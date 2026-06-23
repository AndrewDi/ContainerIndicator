import SwiftUI
import Charts

struct ContentView: View {
    @Environment(ContainerManager.self) private var manager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: manager.systemStatus == .running ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(manager.systemStatus == .running ? .green : .red)
                Text(String(localized: "content.service_running \(manager.systemStatus.displayName)"))
                
                Spacer()
                
                if manager.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                
                Button {
                    Task { await manager.silentCheckSystemStatus() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(manager.isLoading)
            }
            .padding()
            .background(.bar)
            
            HStack(spacing: 12) {
                if manager.systemStatus == .running {
                    Button {
                        Task { await manager.stopSystem() }
                    } label: {
                        Label(String(localized: "content.stop_service"), systemImage: "stop.circle")
                    }
                    .controlSize(.regular)
                } else {
                    Button {
                        Task { await manager.startSystem() }
                    } label: {
                        Label(String(localized: "content.start_service"), systemImage: "play.circle")
                    }
                    .controlSize(.regular)
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
                
                Text("\(String(localized: "content.containers_count \(manager.containers.count)")) | \(String(localized: "content.machines_count \(manager.machines.count)")) | \(String(localized: "content.running_count \(manager.totalRunningCount)"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
            
            Divider()
            
            if manager.systemStatus != .running {
                ContentUnavailableView(
                    String(localized: "content.service_not_running"),
                    systemImage: "cube.transparent",
                    description: Text(String(localized: "content.start_service_first"))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.containers.isEmpty && manager.machines.isEmpty {
                ContentUnavailableView(
                    String(localized: "content.no_containers_machines"),
                    systemImage: "cube",
                    description: Text(String(localized: "content.no_containers_or_machines"))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !manager.containers.isEmpty {
                            Section {
                                ForEach(manager.containers) { container in
                                    ContainerRow(container: container)
                                    Divider()
                                }
                            } header: {
                                HStack {
                                    Text(String(localized: "content.section_containers"))
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.bar)
                            }
                        }
                        
                        if !manager.machines.isEmpty {
                            Section {
                                ForEach(manager.machines) { machine in
                                    MachineRow(machine: machine)
                                    Divider()
                                }
                            } header: {
                                HStack {
                                    Text(String(localized: "content.section_machines"))
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.bar)
                            }
                        }
                    }
                }
            }
            
            if let error = manager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                    Button(String(localized: "content.clear")) {
                        manager.errorMessage = nil
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(.orange.opacity(0.1))
            }
        }
        .frame(minWidth: 650, minHeight: 400)
        .task {
            await manager.silentCheckSystemStatus()
        }
    }
}

struct ContainerRow: View {
    @Environment(ContainerManager.self) private var manager
    let container: ContainerInfo
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "cube")
                .foregroundStyle(container.status == .running ? .green : .gray)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(container.name)
                        .fontWeight(.medium)
                    if container.status == .running {
                        Text(container.statusText)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    } else {
                        Text(container.statusText)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                
                Text(container.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 2) {
                    GridRow {
                        Text(String(localized: "label.image"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(container.image)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    if !container.hostname.isEmpty {
                        GridRow {
                            Text(String(localized: "label.hostname"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(container.hostname)
                                .font(.caption)
                        }
                    }
                    GridRow {
                        Text(String(localized: "label.platform"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(container.platform)
                            .font(.caption)
                    }
                    GridRow {
                        Text(String(localized: "label.cpu_memory"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(String(localized: "label.cores \(container.totalCpus)")) / \(container.memoryFormatted)")
                            .font(.caption)
                    }
                }
            }
            
            if container.status == .running {
                ContainerStatsGridCompact(containerId: container.id)
                    .frame(minWidth: 169, maxWidth: 480)
            }
            
            Spacer(minLength: 0)
            
            VStack {
                if container.status == .running {
                    Button(String(localized: "container.stop")) {
                        Task { await manager.stopContainer(container) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button(String(localized: "container.restart")) {
                        Task { await manager.restartContainer(container) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button(String(localized: "container.start")) {
                        Task { await manager.startContainer(container) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ContainerStatsGridCompact: View {
    @Environment(ContainerManager.self) private var manager
    let containerId: String

    var stats: [ContainerStat] {
        manager.getStats(for: containerId)
    }

    var body: some View {
        if stats.count >= 2 {
            GeometryReader { geo in
                let spacing: CGFloat = 4
                let chartWidth = (geo.size.width - spacing) / 2
                let chartHeight = (geo.size.height - spacing) / 2

                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        MiniStatChart(
                            icon: "externaldrive",
                            data: stats,
                            values: { stat in Double(stat.ioTotal) },
                            color: .orange,
                            formatValue: { stat in Self.formatBytes(stat.ioTotal) }
                        )
                        .frame(width: chartWidth, height: chartHeight)

                        MiniStatChart(
                            icon: "cpu",
                            data: stats,
                            values: { stat in
                                guard stats.count >= 2 else { return 0 }
                                let currentIndex = stats.firstIndex(where: { $0.id == stat.id }) ?? 0
                                guard currentIndex > 0 else { return 0 }
                                let prev = stats[currentIndex - 1]
                                let deltaUsec = Double(stat.cpuUsageUsec - prev.cpuUsageUsec)
                                let deltaTime = stat.timestamp.timeIntervalSince(prev.timestamp)
                                guard deltaTime > 0 else { return 0 }
                                return (deltaUsec / 1_000_000) / deltaTime * 100
                            },
                            color: .blue,
                            formatValue: { stat in
                                guard stats.count >= 2 else { return "0%" }
                                let currentIndex = stats.firstIndex(where: { $0.id == stat.id }) ?? 0
                                guard currentIndex > 0 else { return "0%" }
                                let prev = stats[currentIndex - 1]
                                let deltaUsec = Double(stat.cpuUsageUsec - prev.cpuUsageUsec)
                                let deltaTime = stat.timestamp.timeIntervalSince(prev.timestamp)
                                guard deltaTime > 0 else { return "0%" }
                                let percentage = (deltaUsec / 1_000_000) / deltaTime * 100
                                return String(format: "%.0f%%", percentage)
                            }
                        )
                        .frame(width: chartWidth, height: chartHeight)
                    }

                    HStack(spacing: spacing) {
                        MiniStatChart(
                            icon: "memorychip",
                            data: stats,
                            values: { stat in Double(stat.memoryUsageBytes) },
                            color: .green,
                            formatValue: { stat in
                                let pct = stat.memoryPercentage
                                return String(format: "%.0f%%", pct)
                            }
                        )
                        .frame(width: chartWidth, height: chartHeight)

                        MiniStatChart(
                            icon: "network",
                            data: stats,
                            values: { stat in Double(stat.networkTotal) },
                            color: .purple,
                            formatValue: { stat in Self.formatBytes(stat.networkTotal) }
                        )
                        .frame(width: chartWidth, height: chartHeight)
                    }
                }
            }
            .frame(minWidth: 160, maxWidth: 240, minHeight: 80, maxHeight: 100)
        } else if !stats.isEmpty {
            HStack {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    static func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MiniStatChart: View {
    let icon: String
    let data: [ContainerStat]
    let values: (ContainerStat) -> Double
    let color: Color
    let formatValue: (ContainerStat) -> String
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: max(7, geo.size.width * 0.14)))
                        .foregroundStyle(color)
                    if let lastStat = data.last {
                        Text(formatValue(lastStat))
                            .font(.system(size: max(7, geo.size.width * 0.14)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                
                Chart(Array(data.enumerated()), id: \.element.id) { index, stat in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", values(stat))
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    AreaMark(
                        x: .value("Index", index),
                        y: .value("Value", values(stat))
                    )
                    .foregroundStyle(color.opacity(0.15))
                    .interpolationMethod(.monotone)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
            .padding(3)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 4))
        }
    }
}

struct MachineRow: View {
    @Environment(ContainerManager.self) private var manager
    let machine: MachineInfo
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "desktopcomputer")
                .foregroundStyle(machine.status == .running ? .green : .gray)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(machine.name)
                        .fontWeight(.medium)
                    if machine.isDefault {
                        Text(String(localized: "label.default"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    if machine.status == .running {
                        Text(machine.statusText)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    } else {
                        Text(machine.statusText)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                
                Text(machine.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 2) {
                    GridRow {
                        Text(String(localized: "label.cpu"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "label.cores \(machine.cpus)"))
                            .font(.caption)
                    }
                    GridRow {
                        Text(String(localized: "label.memory"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(machine.memoryFormatted)
                            .font(.caption)
                    }
                    GridRow {
                        Text(String(localized: "label.disk"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(machine.diskSizeFormatted)
                            .font(.caption)
                    }
                    GridRow {
                        Text(String(localized: "label.created"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(machine.createdDateFormatted)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                if machine.status == .running {
                    Button(String(localized: "machine.stop")) {
                        Task { await manager.stopMachine(machine) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button(String(localized: "machine.restart")) {
                        Task { await manager.restartMachine(machine) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button(String(localized: "machine.start")) {
                        Task { await manager.startMachine(machine) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
        .environment(ContainerManager())
}
