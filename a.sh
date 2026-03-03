#!/bin/bash

# a.sh 脚本

# 设置密码变量
PASS1="oelinux123"
PASS2="linaro1"

# 函数：尝试使用sudo执行命令，自动尝试两个密码
sudo_exec() {
    local cmd="$1"
    
    # 先尝试无密码执行
    echo "尝试执行: $cmd"
    sudo -n $cmd 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "执行成功（无需密码）"
        return 0
    fi
    
    # 尝试第一个密码
    echo "$PASS1" | sudo -S $cmd 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "执行成功（使用密码1）"
        return 0
    fi
    
    # 尝试第二个密码
    echo "$PASS2" | sudo -S $cmd 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "执行成功（使用密码2）"
        return 0
    fi
    
    echo "错误: 无法执行命令: $cmd"
    return 1
}

# 函数：检查Node.js安装是否成功
check_node_installed() {
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        node_version=$(node -v 2>/dev/null)
        npm_version=$(npm -v 2>/dev/null)
        
        if [[ -n "$node_version" && -n "$npm_version" ]]; then
            echo "Node.js安装成功:"
            echo "  Node.js版本: $node_version"
            echo "  npm版本: $npm_version"
            return 0
        fi
    fi
    return 1
}

# 函数：使用NodeSource安装
install_node_nodesource() {
    echo "=== 方法1: 使用NodeSource安装Node.js ==="
    sudo_exec "apt update"
    sudo_exec "apt install -y curl unzip wget gnupg"
    
    # 下载并安装NodeSource setup脚本
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo_exec "apt-get install -y nodejs"
    
    if check_node_installed; then
        echo "NodeSource安装成功"
        return 0
    else
        echo "NodeSource安装失败"
        return 1
    fi
}

# 函数：使用二进制包安装
install_node_binary() {
    echo "=== 方法2: 使用二进制包安装Node.js ==="
    
    # 下载Node.js二进制包
    NODE_URL="https://nodejs.org/dist/v18.20.8/node-v18.20.8-linux-arm64.tar.xz"
    NODE_TAR="node-v18.20.8-linux-arm64.tar.xz"
    NODE_DIR="node-v18.20.8-linux-arm64"
    
    echo "下载Node.js二进制包..."
    if ! wget -O "$NODE_TAR" "$NODE_URL" 2>/dev/null && ! curl -L -o "$NODE_TAR" "$NODE_URL" 2>/dev/null; then
        echo "下载Node.js二进制包失败"
        return 1
    fi
    
    echo "解压Node.js二进制包..."
    tar -xf "$NODE_TAR"
    
    echo "安装Node.js..."
    # 创建目标目录
    sudo_exec "mkdir -p /usr/local/lib/nodejs"
    
    # 复制文件
    sudo_exec "cp -R $NODE_DIR/* /usr/local/lib/nodejs/"
    
    # 创建符号链接
    sudo_exec "ln -sf /usr/local/lib/nodejs/bin/node /usr/local/bin/node"
    sudo_exec "ln -sf /usr/local/lib/nodejs/bin/npm /usr/local/bin/npm"
    sudo_exec "ln -sf /usr/local/lib/nodejs/bin/npx /usr/local/bin/npx"
    
    # 清理临时文件
    rm -rf "$NODE_TAR" "$NODE_DIR"
    
    # 添加到PATH（当前会话）
    export PATH=/usr/local/lib/nodejs/bin:$PATH
    
    if check_node_installed; then
        echo "二进制包安装成功"
        return 0
    else
        echo "二进制包安装失败"
        return 1
    fi
}

# 函数：使用NVM安装
install_node_nvm() {
    echo "=== 方法3: 使用NVM安装Node.js ==="
    
    # 安装NVM
    echo "安装NVM..."
    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>/dev/null && \
       ! wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>/dev/null; then
        echo "NVM安装失败"
        return 1
    fi
    
    # 加载NVM
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
    elif [ -s "$HOME/.nvm/nvm.sh" ]; then
        . "$HOME/.nvm/nvm.sh"
    fi
    
    # 安装Node.js
    echo "使用NVM安装Node.js..."
    nvm install 18.20.8
    nvm use 18.20.8
    nvm alias default 18.20.8
    
    if check_node_installed; then
        echo "NVM安装成功"
        return 0
    else
        echo "NVM安装失败"
        return 1
    fi
}

# 0. 安装nodejs（三种方式）
echo "=== 开始安装 Node.js ==="

# 先检查是否已经安装
if check_node_installed; then
    echo "Node.js 已经安装"
else
    echo "Node.js 未安装，开始安装..."
    
    # 方法1: 使用NodeSource安装
    if ! install_node_nodesource; then
        echo "=== 方法1失败，尝试方法2 ==="
        
        # 方法2: 使用二进制包安装
        if ! install_node_binary; then
            echo "=== 方法2失败，尝试方法3 ==="
            
            # 方法3: 使用NVM安装
            if ! install_node_nvm; then
                echo "=== 所有Node.js安装方法都失败 ==="
                echo "请手动安装Node.js后重新运行脚本"
                exit 1
            fi
        fi
    fi
    
    # 最终验证
    echo "=== 最终验证Node.js安装 ==="
    if check_node_installed; then
        echo "Node.js安装成功！"
    else
        echo "警告: Node.js安装可能存在问题"
        echo "请检查环境变量和安装路径"
    fi
fi

# 1. 创建share文件夹并赋权
echo "=== 创建share文件夹 ==="
mkdir -p ~/share
sudo_exec "chmod 777 ~/share"

# 2. 拉取代码仓库并正确解压到share根目录
echo "=== 拉取代码仓库 ==="
cd ~/share

# 定义仓库URL数组
repo_urls=(
    "https://anlv001-firsapps.hf.space/https://github.com/al198313148/L-share-p/archive/refs/heads/main.zip"
    "https://py.bpbpanel.ip-ddns.com/https://github.com/al198313148/L-share-p/archive/refs/heads/main.zip"
    "https://github.com/al198313148/L-share-p/archive/refs/heads/main.zip"
    "http://file.al1983.netlib.re/share/a0f56f0c-ee61-4c7a-8e90-4590ade78cdf"
)

# 尝试下载并解压到share根目录
download_success=false
for url in "${repo_urls[@]}"; do
    echo "尝试从 $url 下载..."
    if wget -O temp_repo.zip "$url" 2>/dev/null || curl -L -o temp_repo.zip "$url" 2>/dev/null; then
        echo "下载成功，开始解压到share根目录..."
        
        # 创建临时目录用于解压
        mkdir -p temp_extract
        unzip -o temp_repo.zip -d temp_extract/
        
        # 找到解压后的主目录（通常包含README.md、server.js等文件）
        # 首先查找包含server.js的目录
        server_dir=$(find temp_extract -name "server.js" -type f | head -1 | xargs dirname 2>/dev/null)
        
        if [ -n "$server_dir" ] && [ -f "$server_dir/server.js" ]; then
            echo "找到项目主目录: $server_dir"
            # 将项目文件移动到share根目录
            cp -r "$server_dir"/* ./
            # 如果项目目录中有隐藏文件，也复制过来
            cp -r "$server_dir"/.[^.]* ./ 2>/dev/null || true
        else
            # 如果没有找到server.js，直接将解压目录下的所有内容移动到share根目录
            echo "未找到server.js，移动所有文件到share根目录"
            # 查找解压后的第一级目录
            first_dir=$(find temp_extract -maxdepth 1 -type d | grep -v "^temp_extract$" | head -1)
            if [ -n "$first_dir" ]; then
                cp -r "$first_dir"/* ./
                cp -r "$first_dir"/.[^.]* ./ 2>/dev/null || true
            else
                # 如果zip文件直接包含文件而没有目录
                cp -r temp_extract/* ./
                cp -r temp_extract/.[^.]* ./ 2>/dev/null || true
            fi
        fi
        
        # 清理临时文件
        rm -rf temp_repo.zip temp_extract
        download_success=true
        break
    else
        echo "从 $url 下载失败"
    fi
done

if [ "$download_success" = false ]; then
    echo "警告: 所有下载源都失败，请检查网络连接"
fi

# 3. 安装cloudflare
echo "=== 安装 Cloudflare ==="
cloudflare_installed=false

# 首先尝试原来的方法安装
echo "尝试使用仓库方法安装 Cloudflare..."
sudo_exec "mkdir -p --mode=0755 /usr/share/keyrings"

curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | sudo tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null

# 添加仓库到apt源
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo_exec "tee /etc/apt/sources.list.d/cloudflared.list"

# 安装cloudflared
if sudo_exec "apt-get update" && sudo_exec "apt-get install -y cloudflared"; then
    echo "使用仓库方法安装 Cloudflare 成功"
    cloudflare_installed=true
else
    echo "仓库方法安装失败，尝试使用deb包安装..."
    
    # 定义deb包URL数组
    deb_urls=(
        "https://anlv001-firsapps.hf.space/https://github.com/cloudflare/cloudflared/releases/download/2025.11.0/cloudflared-linux-arm64.deb"
        "https://py.bpbpanel.ip-ddns.com/https://github.com/cloudflare/cloudflared/releases/download/2025.11.0/cloudflared-linux-arm64.deb"
        "https://github.com/cloudflare/cloudflared/releases/download/2025.11.0/cloudflared-linux-arm64.deb"
        "http://file.al1983.netlib.re/share/0412d9e1-0233-4f01-ad93-a1a061eed5ee"
    )
    
    # 尝试下载并安装deb包
    for deb_url in "${deb_urls[@]}"; do
        echo "尝试从 $deb_url 下载..."
        if wget -O cloudflared.deb "$deb_url" 2>/dev/null || curl -L -o cloudflared.deb "$deb_url" 2>/dev/null; then
            echo "下载成功，开始安装..."
            if sudo_exec "dpkg -i cloudflared.deb" || sudo_exec "apt-get install -f -y"; then
                echo "使用deb包安装 Cloudflare 成功"
                cloudflare_installed=true
                rm -f cloudflared.deb
                break
            else
                echo "从 $deb_url 安装失败"
            fi
            rm -f cloudflared.deb
        else
            echo "从 $deb_url 下载失败"
        fi
    done
fi

if [ "$cloudflare_installed" = false ]; then
    echo "错误: 所有 Cloudflare 安装方法都失败"
    exit 1
fi

# 4. 启动PM2应用
echo "=== 启动PM2应用 ==="
cd ~/share

# 检查server.js是否存在
if [ ! -f "server.js" ]; then
    echo "错误: 在share根目录下未找到server.js文件"
    echo "当前目录内容:"
    ls -la
    exit 1
fi

# 安装pm2（如果尚未安装）
if ! command -v pm2 &> /dev/null; then
    echo "安装pm2..."
    sudo_exec "npm install -g pm2"
fi

# 安装项目依赖（如果存在package.json）
if [ -f "package.json" ]; then
    echo "安装项目依赖..."
    npm install
fi

# 启动应用
pm2 start server.js --name "app-pdf"
pm2 save

# 设置pm2开机自启
echo "=== 设置PM2开机自启 ==="
startup_output=$(pm2 startup)
echo "$startup_output"

# 提取需要执行的命令
startup_cmd=$(echo "$startup_output" | grep -o "sudo.*$")

if [ -n "$startup_cmd" ]; then
    echo "执行启动命令: $startup_cmd"
    eval "$startup_cmd"
    pm2 save
    echo "PM2开机自启设置完成"
else
    echo "请手动执行上面输出的pm2 startup命令"
    echo "然后再次执行: pm2 save"
fi

echo "=== 脚本执行完成 ==="
echo "当前share目录内容:"
ls -la ~/share
echo "请检查以上输出确认所有步骤执行成功"
