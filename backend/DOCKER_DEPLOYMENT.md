# Docker部署说明

## 概述

本项目已配置完整的Docker部署方案，支持PostgreSQL数据库和Redis缓存的容器化部署。

## 快速开始

### 1. 环境准备

确保系统已安装：
- Docker (>=20.10)
- Docker Compose (>=2.0)

### 2. 配置环境变量

创建 `.env` 文件：
```bash
cp .env.example .env
```

编辑 `.env` 文件：
```env
# AI配置
BASE_URL=https://api.moonshot.cn/v1
API_KEY=your-moonshot-api-key
MODEL=kimi-k2-turbo-preview

# 数据库配置（Docker Compose会自动创建）
DATABASE_URL=postgresql+asyncpg://newstudy_user:newstudy_password@postgres:5432/newstudy
```

### 3. 启动服务

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（慎用）
docker-compose down -v
```

## 服务说明

### PostgreSQL数据库
- **端口**: 5432
- **用户**: newstudy_user
- **密码**: newstudy_password
- **数据库**: newstudy
- **数据持久化**: `postgres_data` volume

### FastAPI后端
- **端口**: 8000
- **健康检查**: `/health`
- **自动重启**: unless-stopped
- **依赖服务**: postgres

### Redis缓存（可选）
- **端口**: 6379
- **数据持久化**: `redis_data` volume

## 开发环境

### 单独启动后端服务

```bash
# 启动数据库
docker-compose up -d postgres

# 本地运行后端（需要安装依赖）
cd backend
uv sync
uv run uvicorn server:app --reload --host 0.0.0.0 --port 8000
```

### 数据库连接

连接到PostgreSQL容器：
```bash
docker exec -it newstudy_postgres psql -U newstudy_user -d newstudy
```

查看数据库：
```sql
\dt  -- 显示所有表
SELECT * FROM notes LIMIT 5;  -- 查看笔记
```

## 生产部署

### 1. 优化配置

编辑 `docker-compose.prod.yml`：
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: newstudy_prod
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - /data/postgres:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app_network

  backend:
    build: .
    restart: always
    environment:
      DATABASE_URL: postgresql+asyncpg://${DB_USER}:${DB_PASSWORD}@postgres:5432/newstudy_prod
      API_KEY: ${API_KEY}
      BASE_URL: ${BASE_URL}
      MODEL: ${MODEL}
    ports:
      - "8000:8000"
    depends_on:
      - postgres
    networks:
      - app_network

networks:
  app_network:
    driver: bridge
```

### 2. 启动生产服务

```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

### 3. 监控和日志

```bash
# 实时查看日志
docker-compose logs -f backend

# 监控资源使用
docker stats

# 备份数据库
docker exec newstudy_postgres pg_dump -U newstudy_user newstudy > backup.sql
```

## 数据迁移

### 从SQLite迁移到PostgreSQL

```bash
# 运行迁移脚本
cd backend
uv run python migrate_to_postgresql.py
```

### 数据备份和恢复

```bash
# 备份数据库
uv run python backup_restore.py backup

# 恢复数据库
uv run python backup_restore.py restore

# 列出备份文件
uv run python backup_restore.py list
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   lsof -i :8000
   lsof -i :5432
   ```

2. **数据库连接失败**
   ```bash
   # 检查数据库容器状态
   docker-compose ps postgres
   
   # 查看数据库日志
   docker-compose logs postgres
   ```

3. **权限问题**
   ```bash
   # 修复文件权限
   sudo chown -R $USER:$USER ./
   ```

4. **依赖安装失败**
   ```bash
   # 重新构建镜像
   docker-compose build --no-cache
   ```

### 性能优化

1. **数据库优化**
   - 调整PostgreSQL配置参数
   - 添加适当索引
   - 定期执行VACUUM

2. **应用优化**
   - 配置连接池大小
   - 启用Redis缓存
   - 调整worker数量

3. **资源限制**
   ```yaml
   services:
     backend:
       deploy:
         resources:
           limits:
             memory: 512M
             cpus: '0.5'
           reservations:
             memory: 256M
             cpus: '0.25'
   ```

## 安全注意事项

1. **网络安全**
   - 不要在生产环境暴露数据库端口
   - 使用防火墙限制访问
   - 配置SSL/TLS

2. **数据安全**
   - 定期备份数据
   - 使用强密码
   - 加密敏感数据

3. **容器安全**
   - 使用非root用户运行
   - 最小权限原则
   - 定期更新镜像

## 监控和日志

### 应用监控

添加健康检查端点：
```python
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now()}
```

### 日志管理

配置日志轮转：
```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 扩展部署

### 负载均衡

使用Nginx作为反向代理：
```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - backend
```

### 水平扩展

```bash
# 启动多个后端实例
docker-compose up --scale backend=3
```

## 更新和维护

### 更新应用

```bash
# 拉取最新代码
git pull

# 重新构建和部署
docker-compose build --no-cache
docker-compose up -d
```

### 数据库维护

```bash
# 连接到数据库
docker exec -it newstudy_postgres psql -U newstudy_user -d newstudy

# 执行维护
VACUUM ANALYZE;
REINDEX DATABASE newstudy;
```