import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
class ContainerManager {
    var systemStatus: SystemStatus = .unknown
    var containers: [ContainerInfo] = []
    var machines: [MachineInfo] = []
    var containerStats: [String: [ContainerStat]] = [:]
    var isLoading = false
    var errorMessage: String?
    
    var runningContainerCount: Int {
        containers.filter { $0.status == .running }.count
    }
    
    var runningMachineCount: Int {
        machines.filter { $0.status == .running }.count
    }
    
    var totalRunningCount: Int {
        runningContainerCount + runningMachineCount
    }
    
    private var containerPath: String?
    private var statsTask: Task<Void, Never>?
    
    init() {
        Task {
            await requestNotificationPermission()
            await findContainerCommand()
            await silentCheckSystemStatus()
            startAutoRefresh()
        }
    }
    
    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func findContainerCommand() async {
        let possiblePaths = [
            "/opt/homebrew/bin/container",
            "/usr/local/bin/container",
            "/usr/bin/container",
            "\(NSHomeDirectory())/.local/bin/container"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                containerPath = path
                return
            }
        }
        
        if let result = try? await executeCommand("/usr/bin/which", arguments: ["container"]),
           result.exitCode == 0 && !result.output.isEmpty {
            containerPath = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func startAutoRefresh() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await silentCheckSystemStatus()
            }
        }
    }
    
    func startStatsCollection() {
        statsTask?.cancel()
        statsTask = Task {
            while !Task.isCancelled {
                await refreshContainerStats()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
    
    func stopStatsCollection() {
        statsTask?.cancel()
        statsTask = nil
    }
    
    private func refreshContainerStats() async {
        guard systemStatus == .running, let commandPath = containerPath else { return }
        
        let runningContainers = containers.filter { $0.status == .running }
        guard !runningContainers.isEmpty else { return }
        
        do {
            let result = try await executeCommand(commandPath, arguments: ["stats", "--no-stream", "--format", "json"])
            
            if result.exitCode == 0 && !result.output.isEmpty {
                if let data = result.output.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    let timestamp = Date()
                    
                    for item in jsonArray {
                        guard let id = item["id"] as? String else { continue }
                        
                        let stat = ContainerStat(
                            timestamp: timestamp,
                            blockReadBytes: item["blockReadBytes"] as? Int ?? 0,
                            blockWriteBytes: item["blockWriteBytes"] as? Int ?? 0,
                            cpuUsageUsec: item["cpuUsageUsec"] as? Int ?? 0,
                            memoryLimitBytes: item["memoryLimitBytes"] as? Int ?? 0,
                            memoryUsageBytes: item["memoryUsageBytes"] as? Int ?? 0,
                            networkRxBytes: item["networkRxBytes"] as? Int ?? 0,
                            networkTxBytes: item["networkTxBytes"] as? Int ?? 0,
                            numProcesses: item["numProcesses"] as? Int ?? 0
                        )
                        
                        if containerStats[id] == nil {
                            containerStats[id] = []
                        }
                        
                        containerStats[id]?.append(stat)
                        
                        if containerStats[id]!.count > 60 {
                            containerStats[id]!.removeFirst()
                        }
                    }
                }
            }
        } catch {
        }
    }
    
    func getStats(for containerId: String) -> [ContainerStat] {
        return containerStats[containerId] ?? []
    }
    
    func silentCheckSystemStatus() async {
        guard let commandPath = containerPath else {
            let newStatus: SystemStatus = .unknown
            if systemStatus != newStatus {
                systemStatus = newStatus
            }
            return
        }
        
        do {
            let result = try await executeCommand(commandPath, arguments: ["system", "status", "--format", "json"])
            
            if result.exitCode == 0 {
                if let data = result.output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    
                    let newStatus = SystemStatus(rawValue: status) ?? .unknown
                    if systemStatus != newStatus {
                        systemStatus = newStatus
                    }
                    
                    if systemStatus == .running {
                        await silentRefreshContainers()
                        await silentRefreshMachines()
                        
                        if runningContainerCount > 0 {
                            if statsTask == nil {
                                startStatsCollection()
                            }
                        } else {
                            stopStatsCollection()
                            containerStats.removeAll()
                        }
                    } else {
                        if !containers.isEmpty { containers = [] }
                        if !machines.isEmpty { machines = [] }
                        stopStatsCollection()
                        containerStats.removeAll()
                    }
                }
            } else if result.exitCode == 1 {
                let newStatus: SystemStatus = .stopped
                if systemStatus != newStatus {
                    systemStatus = newStatus
                }
                if !containers.isEmpty { containers = [] }
                if !machines.isEmpty { machines = [] }
                stopStatsCollection()
                containerStats.removeAll()
            }
        } catch {
            let newStatus: SystemStatus = .unknown
            if systemStatus != newStatus {
                systemStatus = newStatus
            }
            if !containers.isEmpty { containers = [] }
            if !machines.isEmpty { machines = [] }
            stopStatsCollection()
            containerStats.removeAll()
        }
    }
    
    private func silentRefreshContainers() async {
        guard systemStatus == .running, let commandPath = containerPath else { return }
        
        do {
            let result = try await executeCommand(commandPath, arguments: ["list", "--all", "--format", "json"])
            
            if result.exitCode == 0 && !result.output.isEmpty {
                if let data = result.output.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    let newContainers = jsonArray.compactMap { item -> ContainerInfo? in
                        guard let id = item["id"] as? String else { return nil }
                        
                        let configuration = item["configuration"] as? [String: Any]
                        let name = configuration?["id"] as? String ?? id
                        
                        let image = configuration?["image"] as? [String: Any]
                        let imageRef = image?["reference"] as? String ?? ""
                        
                        let status = item["status"] as? [String: Any]
                        let state = status?["state"] as? String ?? "stopped"
                        
                        let networks = configuration?["networks"] as? [[String: Any]]
                        let firstNetwork = networks?.first
                        let networkOptions = firstNetwork?["options"] as? [String: Any]
                        let hostname = networkOptions?["hostname"] as? String ?? ""
                        
                        let resources = configuration?["resources"] as? [String: Any]
                        let cpus = resources?["cpus"] as? Int ?? 0
                        let cpuOverhead = resources?["cpuOverhead"] as? Int ?? 0
                        let memoryInBytes = resources?["memoryInBytes"] as? Int ?? 0
                        
                        let platform = configuration?["platform"] as? [String: Any]
                        let architecture = platform?["architecture"] as? String ?? ""
                        let os = platform?["os"] as? String ?? ""
                        
                        return ContainerInfo(
                            id: id, name: name,
                            status: state.lowercased() == "running" ? .running : .stopped,
                            statusText: state, image: imageRef, hostname: hostname,
                            cpus: cpus, cpuOverhead: cpuOverhead,
                            memoryInBytes: memoryInBytes,
                            architecture: architecture, os: os
                        )
                    }
                    
                    if containers != newContainers {
                        containers = newContainers
                        let currentIds = Set(containers.map { $0.id })
                        containerStats = containerStats.filter { currentIds.contains($0.key) }
                    }
                }
            } else {
                if !containers.isEmpty { containers = [] }
            }
        } catch {
        }
    }
    
    private func silentRefreshMachines() async {
        guard systemStatus == .running, let commandPath = containerPath else { return }
        
        do {
            let result = try await executeCommand(commandPath, arguments: ["machine", "inspect"])
            
            if result.exitCode == 0 && !result.output.isEmpty {
                if let data = result.output.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    let newMachines = jsonArray.compactMap { item -> MachineInfo? in
                        guard let id = item["id"] as? String,
                              let status = item["status"] as? String else { return nil }
                        
                        let createdDate = item["createdDate"] as? String ?? ""
                        let cpus = item["cpus"] as? Int ?? 0
                        let memory = item["memory"] as? Int ?? 0
                        let diskSize = item["diskSize"] as? Int ?? 0
                        let isDefault = item["default"] as? Bool ?? false
                        
                        let image = item["image"] as? [String: Any]
                        let imageRef = image?["reference"] as? String ?? ""
                        
                        let platform = item["platform"] as? [String: Any]
                        let architecture = platform?["architecture"] as? String ?? ""
                        let os = platform?["os"] as? String ?? ""
                        
                        return MachineInfo(
                            id: id, name: id,
                            status: status.lowercased() == "running" ? .running : .stopped,
                            statusText: status, createdDate: createdDate,
                            cpus: cpus, memory: memory, diskSize: diskSize,
                            isDefault: isDefault,
                            imageReference: imageRef,
                            platformArchitecture: architecture,
                            platformOS: os
                        )
                    }
                    
                    if machines != newMachines {
                        machines = newMachines
                    }
                }
            } else {
                if !machines.isEmpty { machines = [] }
            }
        } catch {
        }
    }
    
    func startSystem() async {
        await executeContainerCommand(
            ["system", "start"],
            successTitle: String(localized: "notification.system_started_title"),
            successBody: String(localized: "notification.system_started_body"),
            failureTitle: String(localized: "notification.system_start_failed_title"),
            failureBody: String(localized: "notification.system_start_failed_body")
        )
    }
    
    func stopSystem() async {
        await executeContainerCommand(
            ["system", "stop"],
            successTitle: String(localized: "notification.system_stopped_title"),
            successBody: String(localized: "notification.system_stopped_body"),
            failureTitle: String(localized: "notification.system_stop_failed_title"),
            failureBody: String(localized: "notification.system_stop_failed_body")
        )
    }
    
    func startContainer(_ container: ContainerInfo) async {
        await executeContainerCommand(
            ["start", container.id],
            successTitle: String(localized: "notification.container_started_title"),
            successBody: String(localized: "notification.container_started_body \(container.name)"),
            failureTitle: String(localized: "notification.container_start_failed_title"),
            failureBody: String(localized: "notification.container_start_failed_body \(container.name)")
        )
    }
    
    func stopContainer(_ container: ContainerInfo) async {
        await executeContainerCommand(
            ["stop", container.id],
            successTitle: String(localized: "notification.container_stopped_title"),
            successBody: String(localized: "notification.container_stopped_body \(container.name)"),
            failureTitle: String(localized: "notification.container_stop_failed_title"),
            failureBody: String(localized: "notification.container_stop_failed_body \(container.name)")
        )
    }
    
    func restartContainer(_ container: ContainerInfo) async {
        let stopped = await executeContainerCommand(
            ["stop", container.id],
            successTitle: "",
            successBody: "",
            failureTitle: String(localized: "notification.container_restart_failed_title"),
            failureBody: String(localized: "notification.container_restart_failed_body \(container.name)"),
            showNotification: false
        )
        
        guard stopped else { return }
        
        let started = await executeContainerCommand(
            ["start", container.id],
            successTitle: "",
            successBody: "",
            failureTitle: String(localized: "notification.container_restart_failed_title"),
            failureBody: String(localized: "notification.container_restart_failed_body \(container.name)"),
            showNotification: false
        )
        
        if started {
            sendNotification(
                title: String(localized: "notification.container_restarted_title"),
                body: String(localized: "notification.container_restarted_body \(container.name)")
            )
        }
    }
    
    func startMachine(_ machine: MachineInfo) async {
        await executeContainerCommand(
            ["machine", "run", "-n", machine.name, "-d"],
            successTitle: String(localized: "notification.machine_started_title"),
            successBody: String(localized: "notification.machine_started_body \(machine.name)"),
            failureTitle: String(localized: "notification.machine_start_failed_title"),
            failureBody: String(localized: "notification.machine_start_failed_body \(machine.name)")
        )
    }
    
    func stopMachine(_ machine: MachineInfo) async {
        await executeContainerCommand(
            ["machine", "stop", machine.id],
            successTitle: String(localized: "notification.machine_stopped_title"),
            successBody: String(localized: "notification.machine_stopped_body \(machine.name)"),
            failureTitle: String(localized: "notification.machine_stop_failed_title"),
            failureBody: String(localized: "notification.machine_stop_failed_body \(machine.name)")
        )
    }
    
    func restartMachine(_ machine: MachineInfo) async {
        let stopped = await executeContainerCommand(
            ["machine", "stop", machine.id],
            successTitle: "",
            successBody: "",
            failureTitle: String(localized: "notification.machine_restart_failed_title"),
            failureBody: String(localized: "notification.machine_restart_failed_body \(machine.name)"),
            showNotification: false
        )
        
        guard stopped else { return }
        
        let started = await executeContainerCommand(
            ["machine", "run", "-n", machine.name, "-d"],
            successTitle: "",
            successBody: "",
            failureTitle: String(localized: "notification.machine_restart_failed_title"),
            failureBody: String(localized: "notification.machine_restart_failed_body \(machine.name)"),
            showNotification: false
        )
        
        if started {
            sendNotification(
                title: String(localized: "notification.machine_restarted_title"),
                body: String(localized: "notification.machine_restarted_body \(machine.name)")
            )
        }
    }
    
    @discardableResult
    private func executeContainerCommand(
        _ arguments: [String],
        successTitle: String,
        successBody: String,
        failureTitle: String,
        failureBody: String,
        showNotification: Bool = true
    ) async -> Bool {
        guard let commandPath = containerPath else {
            errorMessage = String(localized: "error.command_not_found")
            if showNotification {
                sendNotification(title: failureTitle, body: failureBody)
            }
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await executeCommand(commandPath, arguments: arguments)
            if result.exitCode == 0 {
                if showNotification {
                    sendNotification(title: successTitle, body: successBody)
                }
                await silentCheckSystemStatus()
                return true
            } else {
                errorMessage = String(localized: "error.command_failed \(result.error)")
                if showNotification {
                    sendNotification(title: failureTitle, body: failureBody)
                }
                return false
            }
        } catch {
            errorMessage = String(localized: "error.execution_failed \(error.localizedDescription)")
            if showNotification {
                sendNotification(title: failureTitle, body: failureBody)
            }
            return false
        }
    }
    
    /// 在后台线程执行命令，避免阻塞主线程
    private func executeCommand(_ path: String, arguments: [String]) async throws -> CommandResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = arguments
                
                var env = ProcessInfo.processInfo.environment
                let paths = [
                    "/opt/homebrew/bin",
                    "/usr/local/bin",
                    "/usr/bin",
                    "/bin",
                    "/usr/sbin",
                    "/sbin",
                    "\(NSHomeDirectory())/.local/bin"
                ]
                env["PATH"] = (paths + [env["PATH"] ?? ""]).joined(separator: ":")
                process.environment = env
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let error = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    let result = CommandResult(
                        exitCode: Int(process.terminationStatus),
                        output: output,
                        error: error
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct CommandResult {
    let exitCode: Int
    let output: String
    let error: String
}

struct ContainerStat: Identifiable {
    let id = UUID()
    let timestamp: Date
    let blockReadBytes: Int
    let blockWriteBytes: Int
    let cpuUsageUsec: Int
    let memoryLimitBytes: Int
    let memoryUsageBytes: Int
    let networkRxBytes: Int
    let networkTxBytes: Int
    let numProcesses: Int
    
    var ioTotal: Int {
        blockReadBytes + blockWriteBytes
    }
    
    var networkTotal: Int {
        networkRxBytes + networkTxBytes
    }
    
    var memoryPercentage: Double {
        guard memoryLimitBytes > 0 else { return 0 }
        return Double(memoryUsageBytes) / Double(memoryLimitBytes) * 100
    }
}

struct ContainerInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let status: ContainerStatus
    let statusText: String
    let image: String
    let hostname: String
    let cpus: Int
    let cpuOverhead: Int
    let memoryInBytes: Int
    let architecture: String
    let os: String
    
    var memoryFormatted: String {
        let gb = Double(memoryInBytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }
    
    var totalCpus: Int {
        cpus * cpuOverhead
    }
    
    var platform: String {
        "\(os)/\(architecture)"
    }
}

struct MachineInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let status: ContainerStatus
    let statusText: String
    let createdDate: String
    let cpus: Int
    let memory: Int
    let diskSize: Int
    let isDefault: Bool
    let imageReference: String
    let platformArchitecture: String
    let platformOS: String

    var memoryFormatted: String {
        let gb = Double(memory) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    var diskSizeFormatted: String {
        let gb = Double(diskSize) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    var createdDateFormatted: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: createdDate) else {
            return createdDate
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }

    var platform: String {
        "\(platformOS)/\(platformArchitecture)"
    }
}

enum ContainerStatus: Equatable {
    case running
    case stopped
}

enum SystemStatus: String, Equatable {
    case running
    case stopped
    case unregistered
    case unknown
    
    var displayName: String {
        switch self {
        case .running: return String(localized: "status.running")
        case .stopped: return String(localized: "status.stopped")
        case .unregistered: return String(localized: "status.unregistered")
        case .unknown: return String(localized: "status.unknown")
        }
    }
    
    var iconName: String {
        switch self {
        case .running: return "cube.fill"
        case .stopped: return "cube"
        case .unregistered: return "cube.transparent"
        case .unknown: return "questionmark.circle"
        }
    }
}
