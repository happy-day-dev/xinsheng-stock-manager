# 小店管家

手机优先的小卖部货品、库存和预计利润管理网站。

## 本地启动

1. 安装 Node.js 20 或更新版本。
2. 执行 `npm install`。
3. 在 [Supabase](https://supabase.com) 创建项目，在 SQL Editor 执行 `supabase/schema.sql`。
4. 将 `.env.example` 复制为 `.env.local`，填入 Project URL 与 anon key（Settings → API）。
5. 在 Authentication → Providers 启用 Email；Authentication → Users 新建你的老板邮箱和密码。
6. 执行 `npm run dev`，打开 `http://localhost:5173`。

局域网手机访问使用 `http://电脑局域网IP:5173`。

## GitHub Pages 发布

1. 在 GitHub 新建一个**公开**仓库，默认分支选择 `main`，并把本项目推送到该仓库。
2. 在仓库 `Settings → Secrets and variables → Actions → Variables` 新建以下两个变量：`VITE_SUPABASE_URL`、`VITE_SUPABASE_ANON_KEY`。
3. 在 `Settings → Pages` 的 Build and deployment 中选择 **GitHub Actions**。
4. 推送完成后，打开 `Actions` 等待 “Deploy to GitHub Pages” 成功；网站地址会显示在部署页面，格式为 `https://你的用户名.github.io/仓库名/`。

项目使用 Hash 路由，因此手机浏览器刷新商品详情等二级页不会出现 GitHub Pages 的 404。

## 首次使用

登录后先在“分类”中新建分类，再录入商品。首页的金额是当前库存的预计值，并非已实际卖出的利润。
