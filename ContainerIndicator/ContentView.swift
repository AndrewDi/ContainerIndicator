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
            
            Spacer(minLength: 0)
            
            if container.status == .running {
                ContainerStatsGridCompact(containerId: container.id)
                    .frame(width: 150, height: 72)
                    .layoutPriority(1)
            }
            
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

enum StatChartType: String, CaseIterable, Identifiable {
    case io, cpu, memory, network
    var id: String { rawValue }
}

struct ChartConfig {
    let type: StatChartType
    let title: String
    let icon: String
    let color: Color
    let unit: MiniStatChart.Unit
    let value: (ContainerStat) -> Double
    let format: (ContainerStat) -> String
}

private func makeChartConfigs(stats: [ContainerStat]) -> [ChartConfig] {
    return [
        ChartConfig(
            type: .io,
            title: String(localized: "chart.io"),
            icon: "externaldrive",
            color: .orange,
            unit: .bytes,
            value: { stat in Double(stat.ioTotal) },
            format: { stat in ContainerStatsGrid.formatBytes(stat.ioTotal) }
        ),
        ChartConfig(
            type: .cpu,
            title: String(localized: "chart.cpu"),
            icon: "cpu",
            color: .blue,
            unit: .percent,
            value: { stat in
                guard stats.count >= 2 else { return 0 }
                let currentIndex = stats.firstIndex(where: { $0.id == stat.id }) ?? 0
                guard currentIndex > 0 else { return 0 }
                let prev = stats[currentIndex - 1]
                let deltaUsec = Double(stat.cpuUsageUsec - prev.cpuUsageUsec)
                let deltaTime = stat.timestamp.timeIntervalSince(prev.timestamp)
                guard deltaTime > 0 else { return 0 }
                return (deltaUsec / 1_000_000) / deltaTime * 100
            },
            format: { stat in
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
        ),
        ChartConfig(
            type: .memory,
            title: String(localized: "chart.memory"),
            icon: "memorychip",
            color: .green,
            unit: .bytes,
            value: { stat in Double(stat.memoryUsageBytes) },
            format: { stat in
                let pct = stat.memoryPercentage
                return String(format: "%.0f%%", pct)
            }
        ),
        ChartConfig(
            type: .network,
            title: String(localized: "chart.network"),
            icon: "network",
            color: .purple,
            unit: .bytes,
            value: { stat in Double(stat.networkTotal) },
            format: { stat in ContainerStatsGrid.formatBytes(stat.networkTotal) }
        )
    ]
}

struct ContainerStatsGridCompact: View {
    let containerId: String
    
    @State private var isHovering = false
    @State private var selectedChart: StatChartType?
    @State private var dismissTask: Task<Void, Never>?
    
    private enum PopoverContent {
        case grid
        case singleChart(StatChartType)
    }
    
    private var popoverContent: PopoverContent? {
        if let chart = selectedChart {
            return .singleChart(chart)
        }
        if isHovering {
            return .grid
        }
        return nil
    }
    
    var body: some View {
        ContainerStatsGrid(containerId: containerId, size: .compact, onChartSelected: selectChart)
            .contentShape(Rectangle())
            .onHover { setHover($0) }
            .popover(isPresented: Binding(
                get: { popoverContent != nil },
                set: { if !$0 { closePopover() } }
            )) {
                popoverBody
            }
    }
    
    @ViewBuilder
    private var popoverBody: some View {
        switch popoverContent {
        case .grid:
            ContainerStatsGrid(containerId: containerId, size: .enlarged, onChartSelected: selectChart)
                .frame(width: 400, height: 280)
                .padding(16)
                .onHover { setHover($0) }
        case .singleChart(let type):
            SingleStatChart(containerId: containerId, type: type)
                .frame(width: 520, height: 340)
                .padding(20)
                .onHover { setHover($0) }
        case .none:
            EmptyView()
        }
    }
    
    private func setHover(_ value: Bool) {
        dismissTask?.cancel()
        if value {
            isHovering = true
        } else {
            dismissTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                isHovering = false
                selectedChart = nil
            }
        }
    }
    
    private func selectChart(_ type: StatChartType) {
        selectedChart = type
    }
    
    private func closePopover() {
        isHovering = false
        selectedChart = nil
    }
}

struct ContainerStatsGrid: View {
    @Environment(ContainerManager.self) private var manager
    let containerId: String
    var size: Size = .compact
    var onChartSelected: ((StatChartType) -> Void)?
    
    enum Size {
        case compact
        case enlarged
    }
    
    var stats: [ContainerStat] {
        manager.getStats(for: containerId)
    }
    
    var body: some View {
        if stats.count >= 2 {
            GeometryReader { geo in
                let spacing: CGFloat = size == .compact ? 2 : 8
                let chartWidth = (geo.size.width - spacing) / 2
                let chartHeight = (geo.size.height - spacing) / 2
                let configs = makeChartConfigs(stats: stats)
                
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        chartView(for: configs[0], width: chartWidth, height: chartHeight)
                        chartView(for: configs[1], width: chartWidth, height: chartHeight)
                    }
                    
                    HStack(spacing: spacing) {
                        chartView(for: configs[2], width: chartWidth, height: chartHeight)
                        chartView(for: configs[3], width: chartWidth, height: chartHeight)
                    }
                }
            }
        } else if !stats.isEmpty {
            HStack {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
    
    private func chartView(for config: ChartConfig, width: CGFloat, height: CGFloat) -> some View {
        MiniStatChart(
            title: config.title,
            icon: config.icon,
            data: stats,
            values: config.value,
            color: config.color,
            formatValue: config.format,
            unit: config.unit,
            size: size
        )
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            onChartSelected?(config.type)
        }
    }
    
    static func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(bytes)
        var index = 0
        
        while value >= 1024, index < units.count - 1 {
            value /= 1024
            index += 1
        }
        
        return String(format: "%.0f %@", value, units[index])
    }
}

struct SingleStatChart: View {
    let containerId: String
    let type: StatChartType
    
    @Environment(ContainerManager.self) private var manager
    
    var stats: [ContainerStat] {
        manager.getStats(for: containerId)
    }
    
    var body: some View {
        if let config = makeChartConfigs(stats: stats).first(where: { $0.type == type }) {
            MiniStatChart(
                title: config.title,
                icon: config.icon,
                data: stats,
                values: config.value,
                color: config.color,
                formatValue: config.format,
                unit: config.unit,
                size: .enlarged
            )
        } else {
            EmptyView()
        }
    }
}

struct MiniStatChart: View {
    let title: String
    let icon: String
    let data: [ContainerStat]
    let values: (ContainerStat) -> Double
    let color: Color
    let formatValue: (ContainerStat) -> String
    var unit: Unit = .bytes
    var size: ContainerStatsGrid.Size = .compact
    
    enum Unit {
        case bytes
        case percent
    }
    
    var body: some View {
        GeometryReader { geo in
            let iconTextSize = max(
                size == .compact ? 6 : 10,
                geo.size.width * (size == .compact ? 0.11 : 0.09)
            )
            let padding: CGFloat = size == .compact ? 2 : 6
            let cornerRadius: CGFloat = size == .compact ? 3 : 8
            
            VStack(spacing: size == .compact ? 1 : 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: iconTextSize))
                        .foregroundStyle(color)
                    if let lastStat = data.last {
                        Text(formatValue(lastStat))
                            .font(.system(size: iconTextSize))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                
                chartBody
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if size == .enlarged {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(padding)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
    
    private var chartBody: some View {
        let chart = Chart(data, id: \.id) { stat in
            LineMark(
                x: .value("Time", stat.timestamp),
                y: .value("Value", values(stat))
            )
            .foregroundStyle(color)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 1))
            
            AreaMark(
                x: .value("Time", stat.timestamp),
                y: .value("Value", values(stat))
            )
            .foregroundStyle(color.opacity(0.15))
            .interpolationMethod(.monotone)
        }
        
        if size == .compact {
            return AnyView(chart
                .chartXAxis(.hidden)
                .chartYAxis(.hidden))
        } else {
            let configured = chart
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.hour().minute().second())
                                    .font(.caption2)
                            }
                        }
                    }
                }
            
            switch unit {
            case .percent:
                return AnyView(configured
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        yAxisMarks(values: .stride(by: 25))
                    })
            case .bytes:
                return AnyView(configured
                    .chartYScale(domain: .automatic(includesZero: true))
                    .chartYAxis {
                        yAxisMarks(values: .automatic(desiredCount: 4))
                    })
            }
        }
    }
    
    private func yAxisMarks(values: AxisMarkValues) -> some AxisContent {
        AxisMarks(position: .leading, values: values) { value in
            AxisGridLine()
            AxisValueLabel {
                if let val = value.as(Double.self) {
                    Text(formatAxisValue(val))
                        .font(.caption2)
                }
            }
        }
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        switch unit {
        case .bytes:
            return ContainerStatsGrid.formatBytes(Int(value))
        case .percent:
            return String(format: "%.0f%%", value)
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
