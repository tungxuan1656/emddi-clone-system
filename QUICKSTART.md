# Quick Start Guide

## 🚀 Setup lần đầu

### 1. Clone repository với submodules

```bash
git clone git@gitlab.emddi.xyz:emddi-software/emddi-customer-clone-system.git
cd emddi-customer-clone-system
git submodule update --init --recursive
```

### 2. Kiểm tra các submodules

```bash
# Kiểm tra trạng thái
git submodule status

# Kết quả mong đợi (có commit hash):
#  abc123... partner-configs (heads/main)
#  def456... emddi-v2 (heads/main)
#  ghi789... emddi-v2-ios (heads/main)
#  jkl012... emddi-v2-android (heads/main)
```

## 📝 Workflow cơ bản

### Tạo partner mới

**Bước 1: Chuẩn bị configs**

Tạo 4 files trong submodule `partner-configs`:
- `{partner-key}.env.txt`
- `{partner-key}.logo.png`
- `{partner-key}.GoogleService-Info.plist`
- `{partner-key}.google-services.json`

Xem chi tiết: [PARTNER_TEMPLATE.md](PARTNER_TEMPLATE.md)

**Bước 2: Commit configs**

```bash
cd partner-configs
git add .
git commit -m "Add partner: abc-taxi"
git push origin main
cd ..
```

**Bước 3: Tạo branch cho partner**

```bash
./clone-partner.sh main --partner abc-taxi
```

Script sẽ:
- ✅ Tạo branch `partners/abc-taxi` trong `emddi-v2`
- ✅ Copy configs từ `partner-configs`
- ✅ Setup Firebase và app icon
- ✅ Create env files cho development/staging/production
- ✅ Commit và push lên remote

**Bước 4: Build app**

```bash
# Build iOS production
./build-branch.sh ios production partners/abc-taxi

# Build Android production
./build-branch.sh android production partners/abc-taxi
```

## 🔄 Update partner hiện có

### Cập nhật configs

```bash
# 1. Sửa configs trong partner-configs
cd partner-configs
# Edit files...
git add .
git commit -m "Update abc-taxi configs"
git push origin main
cd ..

# 2. Re-clone để update branch
./clone-partner.sh main --partner abc-taxi

# 3. Build lại
./build-branch.sh ios production partners/abc-taxi
```

### Cập nhật version

```bash
# Clone với version mới
./clone-partner.sh main --partner abc-taxi --version 5.1.0-26

# Build
./build-branch.sh ios production partners/abc-taxi
```

## 🛠️ Build cho nhiều môi trường

### Development build

```bash
./build-branch.sh ios development partners/abc-taxi
```

Sẽ dùng:
- `.env.development`
- API: `https://api.dev.emddi.net`

### Staging build

```bash
./build-branch.sh ios staging partners/abc-taxi
```

Sẽ dùng:
- `.env.staging`
- API: `https://api.uat.emddi.xyz`

### Production build

```bash
./build-branch.sh ios production partners/abc-taxi
```

Sẽ dùng:
- `.env.production`
- API: `https://api.emddi.com`

## 📱 Build cho cả iOS và Android

```bash
# iOS
./build-branch.sh ios production partners/abc-taxi

# Android (có thể chạy song song)
./build-branch.sh android production partners/abc-taxi
```

Mỗi platform sẽ dùng submodule riêng nên không bị conflict!

## 🔍 Troubleshooting

### Submodules rỗng

```bash
git submodule update --init --recursive
```

### Reset submodule về trạng thái clean

```bash
cd emddi-v2-ios  # hoặc emddi-v2-android, emddi-v2
git reset --hard origin/main
git clean -fd
cd ..
```

### Update tất cả submodules

```bash
git submodule update --remote --merge
```

### Xem branch hiện tại của submodules

```bash
git submodule foreach 'echo $name: $(git rev-parse --abbrev-ref HEAD)'
```

## 💡 Tips

1. **Build song song**: iOS và Android có submodule riêng nên có thể build cùng lúc
2. **Configs centralized**: Tất cả configs lưu trong `partner-configs`, dễ quản lý
3. **Version control**: Mỗi lần clone sẽ tự động commit configs
4. **Branch naming**: Luôn dùng format `partners/{partner-key}`

## 📚 Xem thêm

- [README.md](README.md) - Hướng dẫn chi tiết
- [PARTNER_TEMPLATE.md](PARTNER_TEMPLATE.md) - Template configs
