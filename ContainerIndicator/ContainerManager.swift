import Foundation
import Observation

@MainActor
@Observable
class ContainerManager {
    var isDockerRunning = false
    var containers: [ContainerInfo] = []
    var isLoading = false
    var errorMessage: String?
    
    var runningCount: Int {
        containers.filter { $0.status == .running }.count
    }
    
    init() {
        Task {
            await checkDockerStatus()
            startAutoRefresh()
        }
    }
    
    private func startAutoRefresh() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await checkDockerStatus()
            }
        }
    }
    
    func checkDockerStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await runCommand("docker", "info", "--format", "{{.ServerVersion}}")
            isDockerRunning = result.exitCode == 0
            
            if isDockerRunning {
                await refreshContainers()
            } else {
                containers = []
            }
        } catch {
            errorMessage = "检查 Docker 状态失败: \(error.localizedDescription)"
            isDockerRunning = false
            containers = []
        }
    }
    
    func refreshContainers() async {
        guard isDockerRunning else { return }
        
        do {
            let result = try await runCommand(
                "docker", "ps", "-a",
                "--format", "{{.ID}}|{{.Names}}|{{.Status}}|{{.Image}}"
            )
            
            if result.exitCode == 0 {
                containers = result.output
                    .split(separator: "\n")
                    .filter { !$0.isEmpty }
                    .compactMap { line in
                        let parts = line.split(separator: "|")
                        guard parts.count >= 4 else { return nil }
                        
                        let status = String(parts[2])
                        let containerStatus: ContainerStatus = status.lowercased().contains("up") ? .running : .stopped
                        
                        return ContainerInfo(
                            id: String(parts[0]),
                            name: String(parts[1]),
                            status: containerStatus,
                            image: String(parts[3]),
                            statusText: status
                        )
                    }
            }
        } catch {
            errorMessage = "刷新容器列表失败: \(error.localizedDescription)"
        }
    }
    
    func startContainer(_ container: ContainerInfo) async {
        guard isDockerRunning else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await runCommand("docker", "start", container.id)
            if result.exitCode == 0 {
                await refreshContainers()
            } else {
                errorMessage = "启动容器失败: \(result.error)"
            }
        } catch {
            errorMessage = "启动容器失败: \(error.localizedDescription)"
        }
    }
    
    func stopContainer(_ container: ContainerInfo) async {
        guard isDockerRunning else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await runCommand("docker", "stop", container.id)
            if result.exitCode == 0 {
                await refreshContainers()
            } else {
                errorMessage = "停止容器失败: \(result.error)"
            }
        } catch {
            errorMessage = "停止容器失败: \(error.localizedDescription)"
        }
    }
    
    func restartContainer(_ container: ContainerInfo) async {
        guard isDockerRunning else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await runCommand("docker", "restart", container.id)
            if result.exitCode == 0 {
                await refreshContainers()
            } else {
                errorMessage = "重启容器失败: \(result.error)"
            }
        } catch {
            errorMessage = "重启容器失败: \(error.localizedDescription)"
        }
    }
    
    private func runCommand(_ command: String, _ arguments: String...) async throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let error = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        return CommandResult(
            exitCode: Int(process.terminationStatus),
            output: output,
            error: error
        )
    }
}

struct CommandResult {
    let exitCode: Int
    let output: String
    let error: String
}

struct ContainerInfo: Identifiable {
    let id: String
    let name: String
    let status: ContainerStatus
    let image: String
    let statusText: String
}

enum ContainerStatus {
    case running
    case stopped
}
