# serv00_base

serv00_base 是一个为 serv00 免费主机设计的自动化部署工具。它可以帮助用户在 serv00 上快速部署 Node.js 应用程序，特别是针对视频下载项目 "videodown"。

## 主要特性

- 一键式自动化部署流程，简化 serv00 上的应用程序安装
- 智能配置端口和域名绑定
- 集成 PM2 进程管理器，确保应用程序稳定运行
- 自动生成详细的部署信息页面（info.html）
- 自动配置重启任务，保证服务器重启后应用程序自动恢复运行
- 支持从 Git 仓库克隆项目（默认为 https://github.com/saotv/cobalt.git）
- 自动设置 Node.js 环境（默认版本为 20）
- 支持 pnpm 包管理器
- 自动设置 Python 虚拟环境
- 自动更新环境变量

## 使用前提

- 拥有 serv00 免费主机账号
- 具备基本的命令行操作能力
- 确保服务器上已安装 Git

## 快速开始

1. 通过 SSH 连接到您的 serv00 服务器：
   ```bash
   ssh 你的用户名@你的用户名.serv00.net
   ```

2. 克隆仓库并运行安装脚本：
   ```bash
   git clone https://github.com/aigem/free_video_download_serv00.git
   cd free_video_download_serv00
   bash setup.sh main
   ```

3. 按照提示完成配置过程，包括：
   - 选择或添加端口
   - 绑定网站域名
   - 等待自动安装和配置过程完成

4. 安装完成后，访问生成的 info.html 页面查看部署详情

## 配置文件说明

安装过程会在 `/usr/home/你的用户名/videodown/src/config.sh` 生成一个配置文件，包含以下关键信息：

- `PROJECT_NAME`: 项目名称（默认为 "videodown"）
- `APP_PORT`: 应用程序运行的端口号
- `MY_WEBSITE`: 绑定的域名
- `GIT_REPO`: Git 仓库地址
- `GIT_REPO_DIR`: Git 仓库目录名
- `NODE_Version`: Node.js 版本（默认为 20）
- `PYTHON_VIRTUALENV`: Python 虚拟环境路径
- 其他相关配置信息

## 自定义应用部署

要部署您自己的应用：

1. 修改 `setup.sh` 中的 `PROJECT_NAME`、`GIT_REPO` 和 `GIT_REPO_DIR` 变量
2. 确保您的应用程序使用配置文件中指定的端口号
3. 如果需要，修改 `prepare_application()` 函数以适应您的应用程序需求
4. 根据需要调整 `src/package.txt` 和 `src/requirements.txt` 文件中的依赖项

## 重启脚本

本工具会自动设置一个重启脚本，确保服务器重启后您的应用能自动启动。重启脚本路径为：
/usr/home/你的用户名/videodown/src/setup.sh main_reboot


## 日志文件

- 安装日志：`/usr/home/你的用户名/videodown/setup_log.txt`
- PM2 日志：`/usr/home/你的用户名/domains/你的域名/public_html/pm2_log.txt`

## 常见问题解决

- 应用无法启动：检查 PM2 日志 `pm2 logs`
- 端口冲突：确保您的应用监听的是配置文件中指定的端口
- 依赖问题：检查 Node.js 环境是否正确设置，可能需要手动运行 `npm install` 或 `pnpm install`
- Python 虚拟环境问题：检查虚拟环境是否正确激活，可能需要手动运行 `source /path/to/venv/bin/activate`

## 注意事项

- 请勿手动修改 `reboot_run.sh` 文件，它确保服务器重启后您的应用能自动启动
- 定期备份您的应用程序和数据
- 遵守 serv00 的使用条款和政策
- 如果修改了 Node.js 版本或 Python 虚拟环境，请确保更新相应的环境变量

## 高级功能

- **自动更新环境变量**：脚本会自动更新 `.bash_profile` 文件，确保所有必要的路径都被正确添加到环境变量中。
- **智能端口管理**：脚本可以自动列出可用端口，并允许用户选择或添加新端口。
- **自动生成信息页面**：安装完成后，会自动生成一个包含所有重要信息的 `info.html` 页面。
- **灵活的 Git 仓库支持**：可以轻松更改 Git 仓库地址和目录名，以适应不同的项目需求。

## 贡献指南

欢迎贡献！如果您想为项目做出贡献，请遵循以下步骤：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 许可证

本项目采用 MIT 许可证。详情请见 [LICENSE](LICENSE) 文件。

## 联系方式

如有任何问题或建议，请通过以下方式联系我们：

- 项目 Issues: [https://github.com/你的用户名/serv00_base/issues](https://github.com/你的用户名/serv00_base/issues)
- 邮箱: [your-email@example.com](mailto:your-email@example.com)

感谢您使用 serv00_base！祝您在 serv00 上享受愉快的部署体验！