# MacServerMonitor - Claude Code 开发指南

> 这份文档是项目开发的"宪法"，所有开发决策都应遵循这些原则。

## 项目信息

- **项目名称**: MacServerMonitor
- **Owner**: Sepine Tam (sepinetam@gmail.com)
- **开发模式**: Claude Code 自主开发
- **仓库**: github.com/sepinetam/MacServerMonitor

## 项目愿景

打造一个专业、易用、强大的 macOS 设备监控解决方案，支持单设备和多设备场景，为个人和小团队提供实时监控能力。

---

## 核心开发原则

### 1. 简单优先 (Simplicity First)
- **零配置**: 开箱即用，不需要用户手动配置
- **自动化**: 自动发现、自动连接、自动恢复
- **直观界面**: 一眼就能看懂的功能和操作
- **避免过度工程**: 不为假设的未来需求添加复杂性

### 2. 性能至上 (Performance First)
- **低资源占用**: 应用本身不能成为系统的负担
- **快速响应**: UI 更新及时，操作反馈迅速
- **高效网络**: 最小化网络请求，优化数据传输
- **后台友好**: 后台运行时占用最少资源

### 3. 可靠稳定 (Reliability & Stability)
- **崩溃恢复**: 任何情况下都能自动恢复
- **数据安全**: 配置和持久化数据永不丢失
- **错误处理**: 优雅处理所有异常情况
- **离线缓存**: 网络断开时不影响核心功能

### 4. 用户驱动 (User Driven)
- **快速迭代**: 根据用户反馈快速调整
- **实际需求**: 只解决真实存在的问题
- **渐进增强**: 先实现核心功能，再优化细节
- **开放沟通**: 每个大版本都听取用户意见

### 5. 开放扩展 (Open & Extensible)
- **API 优先**: 所有功能都通过 API 暴露
- **插件架构**: 预留扩展点（v1.7.0+）
- **文档完善**: 让其他人能轻松贡献
- **社区友好**: 欢迎第三方集成

---

## 技术栈规范

### 语言和框架
- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI
- **系统**: macOS 13.0+
- **包管理**: Swift Package Manager

### 架构模式
- **MVVM**: 使用 ObservableObject 作为 ViewModels
- **单例模式**: 共享管理器（ThemeManager, DeviceRegistry等）
- **协议导向**: 定义清晰的接口和抽象

### 代码组织
```
MacServerMonitor/
├── Core/              # 核心逻辑
│   ├── Device/       # 设备相关
│   ├── Settings/     # 设置相关
│   ├── Theme/        # 主题相关
│   └── Sampling/     # 数据采样
├── UI/               # 用户界面
│   ├── Dashboard/    # 主界面
│   ├── Devices/      # 设备管理
│   └── Settings/     # 设置界面
├── Utils/            # 工具类
└── Resources/        # 资源文件
```

---

## 开发工作流

### 1. 功能开发流程
1. **需求确认**: 从 ROADMAP.md 中选择下一个功能
2. **技术方案**: 先思考架构，必要时向用户说明方案
3. **编码实现**: 遵循代码规范，边写边测试
4. **本地测试**: 确保功能正常工作
5. **提交代码**: 使用规范的 commit message
6. **创建 Release**: 打 tag 并触发 GitHub Actions
7. **文档更新**: 更新 README.md 和 ROADMAP.md

### 2. Commit Message 规范
```
<type>: <description>

[可选的详细说明]
```

**类型 (type)**:
- `feat`: 新功能
- `fix`: 修复 bug
- `refactor`: 重构（不改变功能）
- `perf`: 性能优化
- `docs`: 文档更新
- `style`: 代码格式调整
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例**:
```bash
git commit -m "feat: add alert history recording"
git commit -m "fix: resolve memory leak in metrics collection"
git commit -m "refactor: simplify device discovery logic"
```

**禁止事项**:
- ❌ 不要添加 "Co-Authored-By" 等合著者信息
- ❌ commit message 使用英文（但中文注释在代码中是允许的）

### 3. 版本发布流程
```bash
# 1. 更新版本号（在 ROADMAP.md 和代码中如果需要）
# 2. 提交所有更改
git add .
git commit -m "feat: complete v1.x.x features"

# 3. 创建并推送 tag
git tag v1.x.x
git push origin main --tags

# 4. GitHub Actions 自动构建并上传到 Release
# 5. 在 GitHub 上编辑 Release notes
```

### 4. 测试要求
- **必须测试**: 所有新功能必须本地测试
- **边界情况**: 考虑网络断开、设备离线等异常情况
- **性能测试**: 确保内存占用合理（< 100MB）
- **UI 测试**: 验证所有视图在不同主题下的显示

---

## 代码规范

### Swift 代码风格

#### 命名规范
```swift
// 类名和结构体：大驼峰
class DeviceManager { }
struct DeviceMetrics { }

// 属性和方法：小驼峰
var deviceName: String
func fetchMetrics() { }

// 常量：小驼峰或全大写（根据作用域）
let maxRetryCount = 3
let API_BASE_URL = "https://api.example.com"

// 枚举：小驼峰
enum DeviceStatus {
    case online, offline
}
```

#### 注释规范
```swift
/// 函数注释使用三斜线，写明功能、参数、返回值
/// - Parameters:
///   - hostname: 设备的主机名
///   - timeout: 超时时间（秒）
/// - Returns: 是否连接成功
func connectDevice(hostname: String, timeout: Int) -> Bool {
    // 复杂逻辑的行内注释可以使用双斜线，中文注释是可以的
    // 但函数级别的注释应该是英文的
    return true
}

// MARK: - 使用 MARK 分隔代码区域
// MARK: - Properties
// MARK: - Public Methods
// MARK: - Private Methods
```

#### 组织结构
```swift
import SwiftUI

// 1. 类型定义
final class MyManager: ObservableObject {

    // 2. MARK: - Properties
    // 2.1 Static
    static let shared = MyManager()

    // 2.2 Published
    @Published var isLoading = false

    // 2.3 Private
    private var timer: Timer?

    // 3. MARK: - Initialization
    private init() { }

    // 4. MARK: - Public Methods
    func start() { }

    // 5. MARK: - Private Methods
    private func doWork() { }
}
```

### SwiftUI 视图规范

```swift
struct MyView: View {
    // 1. StateObjects 和 States
    @StateObject private var manager = Manager.shared
    @State private var isShowing = false

    // 2. Body
    var body: some View {
        // 使用 @ViewBuilder 处理复杂视图
        contentView
    }

    // 3. 私有视图计算属性
    @ViewBuilder
    private var contentView: some View {
        VStack {
            header
            content
        }
    }

    @ViewBuilder
    private var header: some View {
        Text("Header")
    }
}
```

---

## 文件和资源管理

### 文件命名
- **Swift 文件**: 大驼峰，与类型名一致
  - `DeviceManager.swift` 包含 `DeviceManager`
- **资源文件**: 小驼峰或短横线
  - `app-icon.icns`
  - `default-theme.json`

### UserDefaults 键名
```swift
enum SettingsKey: String {
    case refreshInterval = "refresh_interval"
    case httpServerToken = "http_server_token"
    case theme = "app_theme"
}
```

### 通知名称
```swift
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let openDevices = Notification.Name("openDevices")
}
```

---

## 性能指南

### 内存管理
- **使用 weak self**: 在闭包中避免循环引用
```swift
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.update()
}
```

- **及时清理**: 在不需要时释放资源
```swift
deinit {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

### 网络优化
- **设置超时**: 所有网络请求都要有超时
```swift
request.timeoutInterval = 5
```

- **避免频繁请求**: 使用缓存和节流
```swift
private var lastFetchTime: Date?
func fetchIfNeeded() {
    guard let last = lastFetchTime,
          Date().timeIntervalSince(last) > 5 else {
        return
    }
    // 执行请求
}
```

### UI 性能
- **避免过深层级**: SwiftUI 视图层级不要超过 10 层
- **使用 LazyVGrid/LazyHStack**: 懒加载长列表
- **避免在 body 中做重计算**: 使用计算属性缓存

---

## 错误处理

### 网络错误
```swift
private func fetchMetrics() {
    // 1. 设置超时
    // 2. 检查响应状态
    // 3. 优雅降级
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("[Error] Failed to fetch: \(error.localizedDescription)")
            // 更新状态但不崩溃
            DispatchQueue.main.async {
                self.status = .error
            }
            return
        }
        // 处理数据...
    }.resume()
}
```

### 数据解析错误
```swift
guard let data = data,
      let metrics = try? JSONDecoder().decode(DeviceMetrics.self, from: data) else {
    print("[Error] Failed to decode metrics")
    return
}
```

---

## 安全规范

### Token 管理
- **永远不要硬编码 token**: 使用 UserDefaults 或环境变量
- **HTTPS**: 生产环境必须使用加密传输
- **Token 验证**: 所有 API 请求都要验证 token

### 输入验证
```swift
// 验证用户输入
guard !hostname.isEmpty, hostname.count < 256 else {
    return
}

// 验证 URL
guard let url = URL(string: urlString) else {
    return
}
```

---

## 测试指南

### 单元测试（当前未实现，未来计划）
```swift
func testDeviceParsing() {
    let json = """
    {"name": "Test", "hostname": "test.local"}
    """
    // 测试解析逻辑
}
```

### 手动测试清单
- [ ] 应用启动正常
- [ ] 设置修改生效
- [ ] 主题切换正常
- [ ] 设备发现工作
- [ ] 网络断开时应用不崩溃
- [ ] 内存占用正常（< 100MB）
- [ ] CPU 占用正常（< 5%）

---

## 优先级判断

当有多个功能可以选择时，按以下优先级排序：

1. **高优先级**: 核心功能、性能问题、稳定性问题
2. **中优先级**: 用户体验改进、可视化增强
3. **低优先级**: 界面美化、高级功能、插件系统

参考 ROADMAP.md 中的版本计划。

---

## 用户沟通

### 响应用户请求
1. **理解需求**: 先搞清楚用户真正想要什么
2. **提出方案**: 简要说明实现思路（如果复杂）
3. **自主决策**: 用户说"你自己决定"时，遵循本文档的原则
4. **及时反馈**: 遇到问题及时沟通，不要闷头做

### 决策原则
- 用户明确要求 → 按要求做
- 用户说"你自己决定" → 遵循 ROADMAP.md 和本 CLAUDE.md
- 不确定时 → 先做框架/原型，向用户确认

---

## 项目维护

### 文档更新
- 每个大版本后更新 ROADMAP.md
- 重大架构变更更新本 CLAUDE.md
- API 变更更新 README.md

### 代码审查
- 所有代码提交前 self-review
- 检查是否符合本 CLAUDE.md 的规范
- 确保没有明显的性能问题或安全隐患

### 技术债务
- 记录已知的 TODO 和 FIXME
- 在 ROADMAP.md 的未来版本中规划解决
- 避免技术债务积累

---

## 附录

### 相关文件
- `ROADMAP.md`: 产品路线图
- `README.md`: 用户文档
- `CLAUDE.md`: 本文件（开发指南）

### Git 工作流
```bash
# 查看状态
git status

# 查看差异
git diff

# 暂存文件
git add <file>

# 提交
git commit -m "type: description"

# 推送
git push origin main

# 创建标签
git tag v1.x.x
git push origin main --tags
```

### 构建命令
```bash
# 本地构建
./build.sh <version>

# 仅构建 app
swift build -c release

# 创建 DMG
./create-dmg.sh <version>
```

---

## 最后更新

- **更新时间**: 2026-02-02
- **维护者**: Claude Code (AI Assistant)
- **Owner**: Sepine Tam

---

> 记住：这些原则是指导，不是束缚。在特殊情况下，可以根据实际需求灵活调整，但要说明理由。
