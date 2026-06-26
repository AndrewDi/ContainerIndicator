import Foundation

struct ContainerCreateParameters {
    // Basic
    var image: String = ""
    var name: String = ""
    var arguments: [String] = []

    // Resource
    var cpus: String = ""
    var memory: String = ""

    // Process options
    var environmentVariables: [String] = []
    var envFiles: [String] = []
    var gid: String = ""
    var interactive: Bool = false
    var tty: Bool = false
    var user: String = ""
    var uid: String = ""
    var workdir: String = ""
    var ulimits: [String] = []

    // Management options
    var arch: String = ""
    var capAdd: [String] = []
    var capDrop: [String] = []
    var cidfile: String = ""
    var detach: Bool = true
    var dns: [String] = []
    var dnsDomain: String = ""
    var dnsOptions: [String] = []
    var dnsSearch: [String] = []
    var entrypoint: String = ""
    var useInit: Bool = false
    var initImage: String = ""
    var kernel: String = ""
    var labels: [String] = []
    var mounts: [String] = []
    var network: String = ""
    var noDns: Bool = false
    var os: String = ""
    var platform: String = ""
    var publish: [String] = []
    var publishSockets: [String] = []
    var readOnly: Bool = false
    var remove: Bool = false
    var rosetta: Bool = false
    var runtime: String = ""
    var ssh: Bool = false
    var shmSize: String = ""
    var tmpfs: [String] = []
    var virtualization: Bool = false
    var volumes: [String] = []
}
