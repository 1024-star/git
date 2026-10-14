/// 全局配置：后端 API 基地址（统一在此处修改，避免散落在各 API 客户端中）。
///
/// 统一使用电脑真实局域网 IP（cmd 执行 `ipconfig`，取 WLAN/以太网网卡的 IPv4）：
/// - 雷电（LDPlayer）请求 `10.0.2.2` 发不到后端；MuMu/官方 AVD 虽然支持该别名，
///   但为了跨模拟器（雷电/夜神/MuMu/AVD）通用，统一改用局域网 IP。
/// - 后端必须监听 0.0.0.0（app-spring 的 application.properties 已显式配置）。
/// - 换网络导致 IP 变化时，只需同步修改下面这一行。
/// - 注意：VMware 虚拟网卡（VMnet1/VMnet8 的 192.168.x.x）不是真实局域网 IP，不要用。
const String kApiBaseUrl = 'http://10.196.92.100:9900';
