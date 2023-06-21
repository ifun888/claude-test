#镜像模板为node:18-alpine
FROM node:18-alpine AS base
#基础模板
FROM base AS deps
#添加libc6-compat安装包
RUN apk add --no-cache libc6-compat
#设置工作路径
WORKDIR /app
#拷贝依赖到安装路径
COPY package.json yarn.lock ./
#配置仓库
# 使用国内镜像，加速下面 apk add下载安装alpine不稳定情况
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
#安装依赖
RUN yarn install
#新建一个镜像
FROM base AS builder
#审计，添加git安装包
RUN apk update && apk add --no-cache git
RUN git config --global url."https://github.com.cnpmjs.org/".insteadOf "https://github.com/"
#设置环境变量
ENV OPENAI_API_KEY=""
ENV CODE=""
#设置工作路径
WORKDIR /app
#拷贝依赖到安装路径
COPY --from=deps /app/node_modules ./node_modules
#拷贝源文件
COPY . .
#编译文件
RUN yarn build
#配置新镜像
FROM base AS runner
#设置工作路径
WORKDIR /app
ENV OPENAI_API_KEY=""
ENV CODE=""
#把编译出来的内容添加到工作路径中
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/server ./.next/server
#暴露㐰
EXPOSE 3000
#如果有代理，设置代理，没有则运行服务器
#CMD node server.js
# 指定容器启动时要运行的命令，这里是yarn start命令。
CMD ["node", "server.js"]