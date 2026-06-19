import SwiftUI

struct MenuBarView: View {
    @Environment(ContainerManager.self) private var manager
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Docker 状态
            HStack {
                Image(systemName: manager.isDockerRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(manager.isDockerRunning ? .green : .red)
                Text(manager.isDockerRunning ? "Docker 运行中" : "Docker 未运行")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // 容器列表
            if manager.isDockerRunning {
                if manager.containers.isEmpty {
                    Text("暂无容器")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    ForEach(manager.containers) { container in
                        ContainerMenuItem(container: container)
                    }
                }
                
                Divider()
            }
            
            // 操作按钮
            Button {
                Task { await manager.checkDockerStatus() }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(manager.isLoading)
            
            Button {
                openWindow(id: "main")
            } label: {
                Label("容器管理...", systemImage: "square.grid.2x2")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("退出 ContainerIndicator") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

struct ContainerMenuItem: View {
    @Environment(ContainerManager.self) private var manager
    let container: ContainerInfo
    
    var body: some View {
        Menu {
            if container.status == .running {
                Button("停止") {
                    Task { await manager.stopContainer(container) }
                }
                Button("重启") {
                    Task { await manager.restartContainer(container) }
                }
            } else {
                Button("启动") {
                    Task { await manager.startContainer(container) }
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(container.status == .running ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text(container.name)
                Spacer()
                Text(container.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
