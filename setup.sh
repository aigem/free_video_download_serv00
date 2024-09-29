#!/bin/bash

# serv00_base 重启脚本
# 版本: 2.0.0
# 描述: 用于在系统重启后自动启动应用程序


# 默认配置
PROJECT_NAME="videodown"
DEFAULT_FRAMEWORK="nodejs"
GIT_REPO="https://github.com/saotv/cobalt.git"
GIT_REPO_DIR="cobalt"
NODE_Version="20"

# 设置项目
setup_project() {
    print_color $BLUE "开始设置项目..."
    print_color $BLUE "本项目：$PROJECT_NAME"
    print_color $BLUE "使用框架：$DEFAULT_FRAMEWORK"
    print_color $BLUE "GIT仓库：$GIT_REPO"
    print_color $BLUE "GIT仓库目录：$GIT_REPO_DIR"
    print_color $BLUE "NODE版本：$NODE_Version"
    print_color $BLUE "如需修改，请在setup.sh中修改默认配置"
    
    # 默认配置 一般不改
    BASH_PROFILE="$USER_HOME/.bash_profile"
    devil binexec on
    USER_HOME="/usr/home/$(whoami)"
    CONFIG_FILE="$USER_HOME/$PROJECT_NAME/src/config.sh"
    REBOOT_SCRIPT_PATH="$USER_HOME/$PROJECT_NAME/src/reboot_run.sh"
    VIRTUAL_ENV_PATH="$USER_HOME/$PROJECT_NAME/venv_$PROJECT_NAME"
    setup_log="$USER_HOME/$PROJECT_NAME/setup_log.txt"

    log_message "项目设置完成，开始一键安装$PROJECT_NAME！"
}

# 设置错误处理
set -euo pipefail

# 定义颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示颜色
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 记录日志
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$setup_log"
}

# 创建目录
create_directories() {
    print_color $BLUE "创建必要的目录..."
    mkdir -p "$USER_HOME/$PROJECT_NAME"
    log_message "新建目录: $USER_HOME/$PROJECT_NAME"
}

# 复制同文件夹下的src文件夹的所有内容-必须
copy_files() {
    cp -r src/* "$USER_HOME/$PROJECT_NAME/src/"
    cp "$0" "$USER_HOME/$PROJECT_NAME/src/setup.sh"
    chmod +x "$USER_HOME/$PROJECT_NAME/src/setup.sh"
    log_message "复制文件完成"
}

# 设置端口
setup_port() {
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    print_color $BLUE "【设置 $PROJECT_NAME 端口】你的端口号为: "
    devil port list

    while true; do
        read -p "请输入上面的端口号，如果没有端口请输入【add】来开通一个新的端口号 (最多不超3个): " user_input
        if [[ "$user_input" == "add" ]]; then
            devil port add tcp random
            print_color $GREEN "端口开通成功 "
            devil port list
            read -p "请输入刚才生成的端口号: " app_PORT
            if ! [[ "$app_PORT" =~ ^[0-9]+$ ]] || [ "$app_PORT" -lt 1024 ] || [ "$app_PORT" -gt 65535 ]; then
                print_color $RED "无效的端口号。请输入 1024-65535 之间的数字。"
                continue
            fi
            break
        elif [[ "$user_input" =~ ^[0-9]+$ && "$user_input" -ge 1024 && "$user_input" -le 65535 ]]; then
            app_PORT="$user_input"
            break
        else
            print_color $RED "无效的输入。请输入有效的端口号 (1024-65535) 或 'add'新增端口。"
        fi
    done
    log_message "设置端口: $app_PORT"
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    print_color $BLUE "你的程序必须以以端口: $app_PORT 启动"
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
}

# 绑定网站
bind_website() {
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    print_color $BLUE "现需要绑定网站并指向 $app_PORT"
    print_color $RED "警告：这将会重置网站（删除该网站所有内容）！"
    echo "输入 'yes' 来重置网站 ($(whoami).serv00.net)"
    echo "或输入自定义域名,必须A记录解析到本机IP"
    read -p "或输入 'no' 退出绑定，之后可自行在网页端后台进行设置: " user_input

    case "$user_input" in
        yes)
            print_color $GREEN "开始重置网站..."
            devil www del "$(whoami).serv00.net" &> /dev/null
            ADD_WWW_OUTPUT=$(devil www add "$(whoami).serv00.net" proxy localhost "$app_PORT")
            if echo "$ADD_WWW_OUTPUT" | grep -q "Domain added succesfully"; then
                print_color $GREEN "网站 $(whoami).serv00.net 成功重置。"
                MY_SITE="$(whoami).serv00.net"
            else
                print_color $RED "新建网站失败，之后自行在网页端后台进行设置"
                MY_SITE=""
            fi
            ;;
        no)
            print_color $BLUE "跳过网站设置。之后可自行在网页端后台进行设置。"
            MY_SITE=""
            ;;
        *)
            custom_domain="$user_input"
            devil www del "$custom_domain"
            ADD_WWW_OUTPUT=$(devil www add "$custom_domain" proxy localhost "$app_PORT")
            if echo "$ADD_WWW_OUTPUT" | grep -q "Domain added succesfully"; then
                print_color $GREEN "网站 $custom_domain 成功绑定。"
                MY_SITE="$custom_domain"
            else
                print_color $RED "绑定网站失败，域名是否解析到本机IP。你之后可自行在网页端后台进行设置"
                MY_SITE=""
            fi
            ;;
    esac
    log_message "绑定网站: $MY_SITE 完成"
}

# 设置nodejs环境
setup_nodejs_env() {
    print_color $BLUE "设置 nodejs 环境..."
    mkdir ~/.npm-global
    npm config set prefix '~/.npm-global' 
    echo 'export PATH=~/.npm-global/bin:~/bin:$PATH ' >> $USER_HOME/.bash_profile
    source $USER_HOME/.bash_profile
    mkdir -p ~/bin && ln -fs /usr/local/bin/node$NODE_Version ~/bin/node && ln -fs /usr/local/bin/npm$NODE_Version ~/bin/npm && source $USER_HOME/.bash_profile
    source $USER_HOME/.bash_profile
    log_message "nodejs 环境设置完成"
    print_color $BLUE "请使用 npm install -g 来安装 各种依赖"

    # 通过 src/package.txt 安装依赖
    CURRENT_DIR=$(pwd)
    cd "$USER_HOME/$PROJECT_NAME/src"
    while read -r package; do
        npm install -g "$package"
    done < package.txt
    cd "$CURRENT_DIR"
    log_message "nodejs 环境设置完成"
}

# 安装 pm2 仅检查文件是否存在并不能保证 PM2 正确安装。建议添加一个版本检查，例如 pm2 --version
install_pm2() {
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    if [ ! -f "$USER_HOME/.npm-global/bin/pm2" ]; then
        print_color $GREEN "正在安装 PM2..."
        npm install pm2 -g || {
            print_color $RED "PM2 安装失败。请检查 npm 是否正确安装。请查看README.md"
            log_message "PM2 安装失败"
            exit 1
        }
    else
        print_color $GREEN "PM2 已安装。"
    fi
    log_message "PM2 安装检查完成"
    pm2 --version
    log_message "PM2 版本检查完成"
}

# 设置python虚拟环境
python_virtual_env() {
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="    
    print_color $GREEN "正在创建Python虚拟环境..."

    #获取当前目录
    CURRENT_DIR=$(pwd)

    # 在项目目录下创建虚拟环境
    cd "$USER_HOME/$PROJECT_NAME"
    virtualenv "$VIRTUAL_ENV_PATH" || {
        print_color $RED "虚拟环境创建失败。"
        log_message "虚拟环境创建失败"
        exit 1
    }
    source "$VIRTUAL_ENV_PATH/bin/activate"

    if [ -z "$VIRTUAL_ENV" ]; then
        print_color $RED "未进入虚拟环境，请手动进入虚拟环境"
        log_message "未能进入虚拟环境"
        exit 1
    fi

    print_color $GREEN "已进入虚拟环境: $VIRTUAL_ENV，并安装依赖"
、
    # 安装依赖
    pip install -r "$USER_HOME/$PROJECT_NAME/src/requirements.txt"

    cd "$CURRENT_DIR"
    log_message "虚拟环境设置完成"
}

# Git下载应用
git_clone() {
    # 如果 GIT_REPO 不为空，则 git clone
    if [ -n "$GIT_REPO" ]; then
        print_color $BLUE "git clone 项目..."
        # 如果 GIT_REPO_DIR 不为空，则 git clone 到 GIT_REPO_DIR 目录
        if [ -n "$GIT_REPO_DIR" ]; then
            git clone $GIT_REPO "$USER_HOME/$PROJECT_NAME/$GIT_REPO_DIR"
        else
            git clone $GIT_REPO "$USER_HOME/$PROJECT_NAME"
        fi
        log_message "git clone 项目完成"
    fi
}

# 准备应用，安装依赖并部署、配置文件
prepare_application() {
    print_color $BLUE "部署应用..."
    #检查pnpm是否安装
    if ! command -v pnpm &> /dev/null; then
        print_color $RED "pnpm 未安装。请检查是否正确安装。请查看README.md"
        log_message "pnpm 未安装"
        print_color $BLUE "安装 pnpm..."
        npm install pnpm -g
    fi
    cd "$USER_HOME/$PROJECT_NAME/$GIT_REPO_DIR/api/src"
    pnpm install
    log_message "应用安装依赖完成"

    # 将 src/.env.example 复制为 .env，并用MY_WEB_URL MY_WEB_PORT MY_WEB_NAME 替换 .env 中的 [MY_WEB_URL] [MY_WEB_PORT] [MY_WEB_NAME]
    cp $USER_HOME/$PROJECT_NAME/src/.env.example $USER_HOME/$PROJECT_NAME/$GIT_REPO_DIR/api/.env
    sed -i "s|[MY_WEB_URL]|$MY_SITE|" $USER_HOME/$PROJECT_NAME/$GIT_REPO_DIR/api/.env
    sed -i "s|[MY_WEB_PORT]|$app_PORT|" $USER_HOME/$PROJECT_NAME/$GIT_REPO_DIR/api/.env
    sed -i "s|[MY_WEB_NAME]|$PROJECT_NAME|" $USER_HOME/$PROJECT_NAME/$GIT_REPO_DIR/api/.env
    log_message "应用配置文件生成完成"
}

# 启动应用
start_application() {
    print_color $GREEN "使用 PM2 启动应用..."
    PM2_START_COMMANDS="npm -- run start"
    pm2 start "$PM2_START_COMMANDS" --name "$PROJECT_NAME"
    
    sleep 10

    if pm2 list | grep -q "$PROJECT_NAME"; then
        print_color $GREEN "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
        print_color $GREEN "$PROJECT_NAME 已成功启动。"   
    else
        print_color $RED "$PROJECT_NAME 启动失败，请检查配置。"
        log_message "$PROJECT_NAME 启动失败"
        exit 1
    fi
    
    pm2 save
    log_message "应用启动成功，PM2 配置已保存"
}

# 添加环境变量到.bash_profile，
update_bash_profile() {
    print_color $BLUE "更新 .bash_profile..."
    PM2_PATH=$(which pm2)
    if [ -f "$BASH_PROFILE" ]; then
        # 删除旧的环境变量
        sed -i.bak '/export PATH="$PM2_PATH/d' "$BASH_PROFILE"
        sed -i.bak '/export PATH="$VIRTUAL_ENV_PATH/bin:$PATH"/d' "$BASH_PROFILE"
        sed -i.bak '/export PATH=~/.npm-global/bin:~/bin:$PATH/d' "$BASH_PROFILE"
    fi

    {
        # 检查以下目录是否存在，存在的才添加到环境变量
        if [ -d "~/.npm-global/bin" ]; then
            echo 'export PATH=~/.npm-global/bin:~/bin:$PATH ' >> "$BASH_PROFILE"
        fi
        if [ -d "$VIRTUAL_ENV_PATH/bin" ]; then
            echo "export PATH=\"$VIRTUAL_ENV_PATH/bin:\$PATH\"" >> "$BASH_PROFILE"
        fi
        if [ -d "$PM2_PATH" ]; then
            echo "export PATH=\"$PM2_PATH:\$PATH\"" >> "$BASH_PROFILE"
        fi
    } >> "$BASH_PROFILE"

    source "$BASH_PROFILE"
    log_message "添加环境变量到.bash_profile 完成"
}

# 生成配置文件
generate_config_file() {
    if [ -z "$MY_SITE" ]; then
        print_color $RED "错误: 网站未成功绑定。请检查之前的步骤。"
        MY_SITE="未绑定,重新安装或自己在网页端后台进行设置"
    fi

    cat <<EOF > "$CONFIG_FILE"
#!/bin/bash

# 项目配置
PROJECT_NAME="$PROJECT_NAME"
APP_ADDRESS="0.0.0.0"
APP_PORT="$app_PORT"
SERV00_USER="$(whoami)"
SERV00_DOMAIN="$(whoami).serv00.net"
USER_HOME="$USER_HOME"
BASE_PROFILE="$BASH_PROFILE"
PM2_PATH="$PM2_PATH"
MY_WEBSITE="$MY_SITE"
PYTHON_VIRTUALENV="$VIRTUAL_ENV_PATH"
START_COMMAND="$PM2_START_COMMANDS"
GIT_REPO="$GIT_REPO"
GIT_REPO_DIR="$GIT_REPO_DIR"
NODE_Version="$NODE_Version"
NODE_PATH="$USER_HOME/node_modules/pm2/bin:$PATH"
EOF
    log_message "配置文件生成: $CONFIG_FILE"
}

# 设置重启脚本并添加到CRONJOB
setup_reboot_script() {
    print_color $BLUE "设置重启脚本..."

    if ! crontab -l | grep -q "$USER_HOME/$PROJECT_NAME/src/setup.sh main_reboot"; then
        (crontab -l 2>/dev/null; echo "@reboot $USER_HOME/$PROJECT_NAME/src/setup.sh main_reboot") | crontab -
    fi
    log_message "重启脚本设置完成"
}

# 检查程序PM2启动状态
check_installation_status() {
    if pm2 list | grep -q "$PROJECT_NAME"; then
        return 0
    else
        return 1
    fi
}

# 生成info.html
generate_info_html() {
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    print_color $GREEN "生成 info.html 文件..."

    # 生成 info.html 文件
    cat <<EOF > "$USER_HOME/domains/$MY_SITE/public_html/info.html"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>项目部署信息</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; }
        h1 { color: #333; }
        .info { background-color: #f4f4f4; padding: 10px; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
        .button { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>项目部署信息</h1>
    <div class="info">
        <p><strong>项目名称:</strong> $PROJECT_NAME</p>
        <p><strong>部署状态:</strong> <span class="$(check_installation_status && echo 'success' || echo 'error')">$(check_installation_status && echo '成功' || echo '失败')</span></p>
        <p><strong>端口:</strong> $app_PORT</p>
        <p><strong>网站地址:</strong> <a href="http://$MY_SITE" target="_blank">http://$MY_SITE</a></p>
        <p><strong>虚拟环境路径:</strong> $VIRTUAL_ENV_PATH</p>
        <p><strong>PM2 路径:</strong> $PM2_PATH</p>
    </div>
    <p>
        <a href="setup_log.txt" class="button" target="_blank">查看安装日志</a>
        <a href="https://github.com/aigem/free_video_download_serv00" class="button" target="_blank">查看Github</a>
    </p>
    <script>
        // 可以在这里添加一些 JavaScript 代码，比如自动刷新状态等
    </script>
</body>
</html>
EOF

    log_message "info.html 文件生成完成"
}

# 复制最终日志文件到 info 目录
copy_log_file() {
    cp "$USER_HOME/$PROJECT_NAME/setup_log.txt" "$USER_HOME/domains/$MY_SITE/public_html/setup_log.txt"
    pm2 logs --lines 100 > "$USER_HOME/domains/$MY_SITE/public_html/pm2_log.txt"
}

# 主程序
main() {
    setup_project
    create_directories
    copy_files
    setup_port
    bind_website
    setup_nodejs_env
    install_pm2
    update_bash_profile
    git_clone
    prepare_application
    start_application
    generate_config_file
    setup_reboot_script

    # 检查安装状态
    if check_installation_status; then
        print_color $GREEN "安装成功!"
    else
        print_color $RED "安装失败，请检查日志文件。http://$MY_SITE/info.html"
    fi

    # 无论成功与否，都生成 info.html
    generate_info_html

    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    print_color $GREEN "安装流程完成。请访问 http://$MY_SITE 查看详细信息。"
    print_color $YELLOW "=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

    cd "$USER_HOME/$PROJECT_NAME"
    log_message "安装流程完成"

    copy_log_file
}

# 重启后执行的程序
main_reboot() {
    print_color $BLUE "重启后执行的程序..."
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_message "重启后执行的程序完成,开始时间: $start_time"
    setup_project
    update_bash_profile
    pm2 resurrect
    pm2 start all
    log_message "重启后PM2尝试启动"

    # 检查安装状态
    if check_installation_status; then
        log_message "重启后安装状态检查,启动成功"
    else
        log_message "重启后安装状态检查,启动失败，重试"
        setup_nodejs_env
        install_pm2
        update_bash_profile
        pm2 resurrect
        pm2 start all
        log_message "再次尝试启动完成"
        # 再次检查安装状态
        if check_installation_status; then
            log_message "再次尝试启动完成"
        else
            log_message "再次尝试启动失败，请检查日志文件或查看README.md"
        fi
    fi
    
    # 无论成功与否，都生成 info.html
    generate_info_html
    log_message "重启后秤生成 info.html"

    cd "$USER_HOME/$PROJECT_NAME"

    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_message "重启后执行的程序完成,结束时间: $end_time"

    copy_log_file
}

# 执行程序
case "$1" in
  main)
    main
    ;;
  main_reboot)  
    main_reboot
    ;;
  *)
    echo "Usage: $0 {main|main_reboot}"
    exit 1
esac