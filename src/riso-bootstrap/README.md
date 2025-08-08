# Riso Bootstrap

Một DevContainer Feature cung cấp thiết lập môi trường phát triển toàn diện với Claude Code CLI và các công cụ phát triển hiện đại.

## 🚀 Tính năng

- **Claude Code CLI**: Tự động cài đặt phiên bản mới nhất của Claude Code
- **Serena Integration** (Tùy chọn): Tích hợp Serena coding agent để phân tích mã nguồn
- **Development Tools**: Git, GitHub CLI, Node.js LTS, Python với pre-commit
- **Auto Configuration**: Tự động mount SSH keys, Claude config và GitHub credentials
- **Smart Project Detection**: Tự động phát hiện tên dự án từ workspace

## 📋 Sử dụng

Thêm vào `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/devcontainers/devcontainer-features/riso-bootstrap:latest": {
      "projectName": "my-project",
      "enableSerena": true
    }
  }
}
```

## ⚙️ Tùy chọn

| Tùy chọn | Kiểu | Mặc định | Mô tả |
|----------|------|----------|-------|
| projectName | string | `""` | Tên dự án (tự động phát hiện nếu để trống) |
| enableSerena | boolean | `false` | Kích hoạt Serena coding agent toolkit |
| isTestMode | boolean | `false` | Chế độ test (tạo mock files cho Serena) |

## 🔧 Các công cụ được cài đặt

### Dependencies
- **Common Utils**: Zsh với Oh My Zsh
- **Git**: Version control
- **GitHub CLI**: GitHub integration
- **Node.js**: LTS version với npm
- **Python**: Latest version với pre-commit

### Post-create
- **npm**: Cập nhật lên phiên bản mới nhất
- **Claude Code**: CLI tool cho Claude AI
- **Serena** (nếu được kích hoạt): Semantic code analysis toolkit

## 📁 Cấu trúc thư mục

```
/usr/local/share/riso-bootstrap/
├── scripts/
│   ├── post-attach.sh
│   ├── post-create.sh
│   └── post-start.sh
├── utils/
│   ├── layer-0/        # Utilities cơ bản
│   │   ├── commands.sh
│   │   ├── logger.sh
│   │   └── mock-generator.sh
│   └── layer-1/        # Operations phức tạp
│       ├── file-ops.sh
│       └── validator.sh
└── riso-bootstrap-options.env
```

## 🔄 Lifecycle Scripts

1. **install.sh**: Copy files và tạo environment config
2. **post-create**: Cài đặt tools và setup môi trường
3. **post-start**: Khởi động services
4. **post-attach**: Cấu hình terminal session

## 🧪 Testing

Feature bao gồm 2 test scenarios:

1. **test-ubuntu-minimal**: Test cài đặt cơ bản
2. **test-ubuntu-with-serena**: Test với Serena integration

Chạy tests:
```bash
devcontainer features test -f riso-bootstrap
```

## 📝 Ví dụ sử dụng

### Basic setup
```json
{
  "features": {
    "ghcr.io/devcontainers/devcontainer-features/riso-bootstrap:latest": {}
  }
}
```

### Với Serena
```json
{
  "features": {
    "ghcr.io/devcontainers/devcontainer-features/riso-bootstrap:latest": {
      "enableSerena": true
    }
  }
}
```

### Custom project name
```json
{
  "features": {
    "ghcr.io/devcontainers/devcontainer-features/riso-bootstrap:latest": {
      "projectName": "my-awesome-project",
      "enableSerena": true
    }
  }
}
```

## 🔒 Security

- SSH keys được mount read-only
- Credentials được bảo vệ với proper permissions
- External downloads được validate trước khi thực thi

## 📄 License

Distributed under the same license as the parent devcontainer-features repository.
