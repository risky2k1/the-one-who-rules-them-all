---
name: fe-react-structure
description: Quy ước cấu trúc thư mục và tổ chức code cho FE React + TypeScript (feature-based) — SPA Vite và Next.js App Router (services/fe). Dùng khi khởi tạo dự án FE mới, thêm feature/màn hình/API module, refactor thư mục, hoặc review xem code mới đặt đúng chỗ chưa.
---

# FE React — Cấu trúc & tổ chức thư mục

Chuẩn rút ra từ một SPA thực tế (Vite + React 19 + TS strict + pnpm), đã loại bỏ các điểm yếu gặp phải. Áp dụng cho dự án mới; với dự án cũ thì migrate dần theo từng feature.

> **Dự án Next.js (ví dụ `services/fe`)**: mục 2, 4, 5, 6 (trừ env), 8, 9, 12 giữ nguyên. Mục 1, 3, 7, 10 được **thay thế** bởi [mục 13](#13-biến-thể-nextjs-app-router). Khi hai chỗ mâu thuẫn, mục 13 thắng.

## 1. Cây thư mục chuẩn

```
<repo>/
├─ src/
│  ├─ main.tsx              # entry: mount <AppProviders/>
│  ├─ app/                  # khung ứng dụng — KHÔNG chứa nghiệp vụ
│  │  ├─ providers.tsx      # i18n, UI-lib ConfigProvider, RouterProvider
│  │  ├─ router.tsx         # khai báo route tree
│  │  ├─ routes.ts          # PATHS: hằng số + builder URL (single source)
│  │  ├─ guards/            # AuthGuard, RoleGuard, <Entity>Guard
│  │  └─ layouts/           # layout bọc <Outlet/> (header, side nav, chrome)
│  ├─ features/             # mỗi domain nghiệp vụ 1 thư mục
│  │  └─ <feature>/
│  │     ├─ index.ts        # public API — thứ duy nhất feature khác được import
│  │     ├─ <Feature>View.tsx   # màn hình gốc (route element)
│  │     ├─ components/     # component con của feature
│  │     ├─ hooks/          # useXxx của feature
│  │     ├─ store.ts        # state (zustand) của feature, nếu cần
│  │     ├─ lib/            # hàm thuần: query, mapping, validation
│  │     ├─ types.ts
│  │     ├─ <feature>.css
│  │     └─ __fixtures__/   # dữ liệu test
│  ├─ shared/               # dùng chung, KHÔNG biết đến feature nào
│  │  ├─ api/
│  │  │  ├─ httpClient.ts   # apiFetch<T>, auth header, xử lý 401
│  │  │  ├─ errors.ts       # ApiError (status, code, traceId, details)
│  │  │  └─ <resource>/     # <resource>Api.ts + <resource>.types.ts + test
│  │  ├─ ui/                # component trình bày thuần, không gọi API
│  │  ├─ hooks/             # hook tổng quát (useMediaQuery, useDebounce…)
│  │  ├─ lib/               # util thuần (format, download…)
│  │  └─ config/            # role, view id, storage keys, hằng số app
│  ├─ theme/                # tokens.ts + applyCssVars.ts (+ theme UI lib)
│  ├─ locales/              # i18n.ts + <lang>.json
│  ├─ assets/               # ảnh, font, global styles
│  └─ test/setup.ts         # setup Vitest (jsdom, matchers)
├─ public/
├─ scripts/                 # script build/tooling (.mjs)
├─ .env.example             # liệt kê mọi VITE_* — .env thật không commit
├─ Dockerfile               # build static → dist/
└─ README.md
```

Không đặt ở gốc repo: tài liệu PoC/benchmark (`POC-*.md`), bản demo/prototype cũ, file build. Những thứ đó để ở repo docs, hoặc thêm vào `.gitignore`.

## 2. Quy tắc phụ thuộc giữa các tầng (bắt buộc)

```
app  ──►  features  ──►  shared  ──►  (thư viện ngoài)
 │            │             ▲
 └────────────┴─► theme, locales
```

| Từ \ Import | app | features | shared | theme/locales |
|---|---|---|---|---|
| **app** | ✓ | ✓ (qua `index.ts`) | ✓ | ✓ |
| **features/A** | ✗ | chỉ `features/B/index.ts` | ✓ | ✓ |
| **shared** | ✗ | ✗ | ✓ | ✓ |

- `shared/` **không bao giờ** import từ `features/` hay `app/`. Ví dụ: `httpClient` cần token thì đọc token từ `shared/auth/tokenStorage.ts` hoặc nhận qua `setTokenProvider()`, chứ không import `features/auth/session`.
- Feature này không import sâu vào file nội bộ của feature khác (`../builder/hooks/x`). Nếu cần dùng chung thì export qua `index.ts`, hoặc nếu là thứ tổng quát thì chuyển xuống `shared/`.
- Khi 2 feature cùng cần một thứ, chuyển nó xuống `shared/`, không để feature này phụ thuộc feature kia.
- Không có vòng phụ thuộc (A → B → A).

## 3. Path alias

Luôn dùng alias `@/`. Không viết `../../../`.

```jsonc
// tsconfig.app.json → compilerOptions
"baseUrl": ".",
"paths": { "@/*": ["src/*"] }
```
```ts
// vite.config.ts
import { fileURLToPath, URL } from 'node:url';
resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
```

Import tương đối chỉ dùng **bên trong cùng một feature** (`./components/X`, `../lib/y`).

## 4. Ép quy tắc bằng ESLint (không dựa vào kỷ luật)

```js
// eslint.config.js — thêm vào rules
'no-restricted-imports': ['error', { patterns: [
  { group: ['@/features/*/*'], message: 'Import feature qua public index: @/features/<name>' },
  { group: ['../../*', '../../../*'], message: 'Dùng alias @/ thay vì ../../' },
]}],
```
Thêm override cho `src/shared/**`: cấm `@/features/*` và `@/app/*`. Dự án lớn hơn có thể dùng `eslint-plugin-boundaries`.

**Giới hạn kích thước cũng ép bằng ESLint**, áp cho toàn bộ `src/**` (không liệt kê từng feature, để module mới tự được kiểm tra):

```js
{ files: ['src/**/*.{ts,tsx}'], rules: {
  'max-lines': ['error', { max: 200, skipBlankLines: true, skipComments: true }],
  'max-lines-per-function': ['error', { max: 100, skipBlankLines: true, skipComments: true }],
  'max-params': ['error', 4], 'max-depth': ['error', 3], complexity: ['error', 15],
  'react/jsx-max-depth': ['error', { max: 6 }],
  'no-console': 'error', '@typescript-eslint/no-explicit-any': 'error', '@typescript-eslint/ban-ts-comment': 'error',
}},
{ files: ['src/app/**/page.tsx', 'src/app/**/layout.tsx'], rules: { 'max-lines': ['error', { max: 40 }] } },
{ files: ['src/features/*/views/**'], rules: { 'max-lines': ['error', { max: 180 }] } },
{ files: ['src/**/*.test.ts', 'src/**/*.test.tsx'], rules: { 'max-lines': ['error', { max: 400 }], 'max-lines-per-function': 'off' } },
{ files: ['src/**/*.data.ts'], rules: { 'max-lines': 'off' } },
```

Code cũ viết trước khi có rule được đưa vào một override "LEGACY baseline" (tắt rule theo **từng file**, không theo thư mục). Danh sách này chỉ được bớt, không được thêm. Không dùng `eslint-disable` để lách.

## 5. Bên trong một feature

- **Ngưỡng tách:** khi thư mục gốc của feature vượt khoảng 15 file, chia vào `components/`, `hooks/`, `lib/`. Khi feature vượt khoảng 80–100 file, tách thành sub-feature (`features/builder-canvas`, `features/builder-inspector`…), mỗi sub-feature có `index.ts` riêng.
- **Kích thước file:** tối đa 200 dòng mỗi file, `View` 180, `page.tsx`/`layout.tsx` 40, mỗi hàm 100 dòng (ESLint chặn, xem mục 4). Vượt ngưỡng thì tách logic ra `hooks/useXxx.ts` và phần UI ra `components/`.
- **Chia theo vai trò, không chia theo phiên bản.** Không dùng `v2/`, `data-v2/`, `poc3*.ts`. Khi cần chạy song song bản cũ và mới, dùng feature flag trong `shared/config`. Xong thì xóa bản cũ.
- Code benchmark/PoC đặt trong `scripts/` hoặc branch riêng, không để trong `src/features`.
- `View.tsx` làm nhiệm vụ điều phối: lấy dữ liệu (hook), giữ state (store), render component con. Hàm thuần (lọc, map, validate) đặt trong `lib/` để test không cần render.

## 6. Tầng API

- Mỗi resource backend có một thư mục `shared/api/<resource>/` gồm `<resource>Api.ts` (các hàm gọi `apiFetch`), `<resource>.types.ts` (DTO) và `<resource>Api.test.ts`.
- Hàm API mỏng, đặt tên theo hành động: `listUsers()`, `createUser(body)`, `updateUserRole(id, role)`. Không chứa state hay UI.
- Lỗi nghiệp vụ được nhận diện bằng predicate: `isUserEmailDuplicate(err)` kiểm tra `ApiError.code`. Component không so sánh chuỗi message.
- Mapping DTO sang model hiển thị đặt ở `features/<f>/lib/`, không đặt trong `shared/api`.
- Base URL lấy từ `import.meta.env.VITE_API_BASE_URL`. Mọi biến `VITE_*` phải có trong `.env.example`.

## 7. Routing, state, i18n, theme

- **Routing:** mọi URL đi qua `PATHS` trong `app/routes.ts`. Không hard-code chuỗi `'/models/...'` trong feature. Guard đặt trong `app/guards/`, layout đặt trong `app/layouts/`. Mỗi feature chỉ đóng góp element (`<XxxView/>`).
- **State:** state server lấy qua hook của feature. State client dùng chung trong feature đặt ở `store.ts` (zustand). State toàn app (session, role) đặt ở `shared/`. Không tạo store global "chứa mọi thứ".
- **i18n:** key có namespace theo feature (`users.create.title`). Mọi chuỗi UI đi qua `t()`.
- **Theme:** màu, font, spacing chỉ khai báo trong `theme/tokens.ts`, rồi map sang CSS variables và theme của UI lib. CSS của feature dùng `var(--token)`, không hard-code mã màu.
- **Layout chrome:** header, side nav, rail chỉ có một nơi (`app/layouts/` + `shared/ui/`). Không tạo thêm thư mục `shell/` song song.

## 8. Đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| Component | `PascalCase.tsx` | `UsersTable.tsx` |
| Màn hình route | `<Name>View.tsx` | `ScenariosView.tsx` |
| Hook | `useXxx.ts` | `useAdminUsers.ts` |
| Hàm thuần / store | `camelCase.ts` | `usersQuery.ts`, `store.ts` |
| API | `<resource>Api.ts`, `<resource>.types.ts` | `usersApi.ts` |
| Thư mục | `kebab-case` | `input-tables/`, `audit-logs/` |
| CSS | `<feature>.css` cạnh View | `users.css` |
| Test | `<file>.test.ts(x)` cạnh file được test | `usersQuery.test.ts` |

## 9. Test

- Test đặt cạnh code (colocate). Dùng Vitest + jsdom + `src/test/setup.ts`.
- Ưu tiên test `lib/` (hàm thuần) và `*Api.ts` (mock `fetch`). Test component cho luồng chính.
- File test dài hơn 400 dòng (ESLint chặn) thì tách theo hành vi (`xxx.create.test.tsx`, `xxx.edit.test.tsx`).
- Fixture đặt trong `__fixtures__/` của feature. Helper mount dùng chung đặt trong `src/test/`.

## 10. Tooling tối thiểu

- TS `strict`, `noUnusedLocals`, `noUnusedParameters`, `verbatimModuleSyntax`. Test files dùng `tsconfig.test.json` riêng.
- ESLint (typescript-eslint + react-hooks + react-refresh) + Prettier + `eslint-config-prettier`.
- Husky v9 (`"prepare": "husky"`): pre-commit chạy `lint-staged`; pre-push chạy `lint`, `format:check`, `typecheck`, `test`.
- Khóa phiên bản qua `engines.node`, `packageManager`, `.nvmrc`.
- Scripts: `dev`, `build` (`tsc -b && vite build`), `test`, `typecheck`, `lint`, `lint:fix`, `format`, `format:check`, `fix`.
- Dockerfile chỉ build static. Host SPA cần fallback về `index.html`.

## 11. Checklist khi thêm feature mới

1. Tạo `src/features/<feature>/` có `index.ts` và `<Feature>View.tsx`.
2. Nếu có API: thêm `src/shared/api/<resource>/` gồm `*Api.ts`, `*.types.ts`, `*Api.test.ts`.
3. Thêm path vào `app/routes.ts` (`PATHS`) và route vào `app/router.tsx` (bọc guard nếu cần).
4. Thêm key i18n theo namespace `<feature>.*` vào mọi file `locales/*.json`.
5. Dùng token từ `theme/`, không hard-code màu.
6. Viết test cho `lib/` và luồng chính của View.
7. `pnpm fix && pnpm test` phải xanh. ESLint không báo import vi phạm tầng.

## 12. Anti-pattern (đã gặp thực tế — tránh)

| Anti-pattern | Thay bằng |
|---|---|
| `shared/api/httpClient` import `features/auth/session` | Token provider nằm trong `shared/` |
| `'../../../shared/x'` lặp lại hàng trăm lần | Alias `@/shared/x` |
| Feature import sâu file nội bộ của feature khác | Public `index.ts` + ESLint chặn |
| `features/data` + `features/data-v2`, `builder/v2/`, `p95/`, `poc3*.ts` | Feature flag; xóa bản cũ; PoC chuyển ra `scripts/` hoặc branch |
| Thư mục gốc feature có khoảng 50 file lẫn lộn | `components/`, `hooks/`, `lib/` hoặc tách sub-feature |
| `View.tsx` dài 1500+ dòng | Tách hook + component con |
| `shell/` và `app/layouts/` cùng làm layout | Một nơi duy nhất |
| Demo/prototype 100MB nằm trong repo app | Repo riêng hoặc `.gitignore` |

## 13. Biến thể Next.js (App Router)

Áp dụng cho `services/fe` (Next 14 App Router, R3F, Tailwind v4, Vitest). Ý tưởng tầng giữ nguyên: **`app` → `features` → `shared`**. Thay đổi chính: `src/app/` của Next **là router**, nên mọi thứ "khung ứng dụng" nằm trong chính `src/app/` theo quy ước file của Next.

### 13.1 Cây thư mục

```
services/fe/
├─ src/
│  ├─ app/                      # CHỈ routing (quy ước Next) — mỏng, không nghiệp vụ
│  │  ├─ layout.tsx             # root layout: <html>, font, <Providers>
│  │  ├─ providers.tsx          # 'use client' — gom context provider toàn app
│  │  ├─ page.tsx               # → import { HomeView } from '@/features/portfolio'
│  │  ├─ not-found.tsx, error.tsx, loading.tsx
│  │  └─ <segment>/
│  │     ├─ layout.tsx          # layout/chrome của segment (thay app/layouts/)
│  │     └─ <child>/page.tsx    # chỉ render <XxxView/> + metadata
│  ├─ features/
│  │  └─ <feature>/             # cấu trúc giống mục 1: index.ts, <Feature>View.tsx,
│  │     ├─ index.ts            #   components/, hooks/, lib/, types.ts, __fixtures__/
│  │     ├─ views/              # khi feature có nhiều màn hình: HomeView, PlayView…
│  │     ├─ scene/              # (tùy chọn) component R3F/three của feature
│  │     └─ …
│  ├─ shared/
│  │  ├─ api/                   # httpClient.ts, errors.ts, <resource>/ (như mục 6)
│  │  ├─ ui/                    # ErrorFallback, LoadingScreen, nút, card…
│  │  ├─ three/                 # (tùy chọn) helper R3F dùng chung: quality, webgl detect
│  │  ├─ hooks/                 # useReducedMotion, useMediaQuery…
│  │  ├─ lib/
│  │  └─ config/                # paths.ts (PATHS), feature flags, storage keys
│  ├─ styles/globals.css        # Tailwind v4: @import "tailwindcss"; @theme { tokens }
│  └─ test/setup.ts
├─ public/
├─ middleware.ts                # (khi cần) guard/redirect — thay app/guards/
├─ next.config.mjs, tsconfig.json, vitest.config.ts
└─ .env.example                 # mọi NEXT_PUBLIC_* và biến server
```

### 13.2 Ánh xạ từ bản SPA

| SPA (mục 1–10) | Next.js |
|---|---|
| `main.tsx` + `app/providers.tsx` | `app/layout.tsx` render `<Providers>` từ `app/providers.tsx` (`'use client'`) |
| `app/router.tsx` | Không có — cây thư mục `src/app/**/page.tsx` là route tree |
| `app/routes.ts` (`PATHS`) | `shared/config/paths.ts` — feature cũng dùng được mà không vi phạm tầng |
| `app/layouts/` + `<Outlet/>` | `layout.tsx` của từng segment, nhận `children` |
| `app/guards/` | `middleware.ts` (redirect phía server) hoặc client guard component trong `features/<f>/` dùng ở `layout.tsx` |
| `<Feature>View.tsx` làm route element | `page.tsx` import View qua `@/features/<f>` — `page.tsx` không chứa logic |
| `import.meta.env.VITE_*` | `process.env.NEXT_PUBLIC_*` (lộ ra client) / `process.env.*` (chỉ server) |
| Alias trong `vite.config.ts` | Đã có `"paths": { "@/*": ["./src/*"] }` trong `tsconfig.json`; Vitest cần alias tương ứng trong `vitest.config.ts` |
| `theme/tokens.ts` + `applyCssVars` | Token khai báo trong `@theme { … }` ở `styles/globals.css`; dùng qua class Tailwind hoặc `var(--color-…)`. Chỉ tạo `tokens.ts` khi three.js cần đọc màu trong JS |
| Dockerfile build static + SPA fallback | Chạy `next start` (fe dùng `rewrites` → **không** `output: 'export'`) |

### 13.3 Server vs Client Component

- `page.tsx` / `layout.tsx` mặc định là Server Component. Giữ chúng như vậy khi được (metadata, fetch dữ liệu tĩnh).
- Đặt `'use client'` ở **lá thấp nhất có thể**, thường là `<Feature>View.tsx` hoặc component có state/effect. Không đặt `'use client'` ở `layout.tsx` gốc.
- Mọi thứ đụng `three`, `@react-three/*`, `window`, `localStorage`, `navigator` phải nằm trong client component. Canvas R3F nặng thì load bằng `next/dynamic(() => import(...), { ssr: false })` từ một client component.
- Hàm trong `lib/` phải thuần (không `window`), để chạy được cả server lẫn Vitest. Truy cập trình duyệt thì gói trong `shared/lib/storage.ts` hoặc hook.
- Không truyền function/class instance từ Server sang Client Component qua props — chỉ dữ liệu serializable.

### 13.4 Gọi API

- Tầng API như mục 6. Phía client gọi đường dẫn tương đối `/api/v1/...` — `next.config.mjs` rewrite sang CMS qua `CMS_INTERNAL_URL` (khai báo ở `.env.example` của repo master). Không hard-code host CMS trong code.
- Contract API lấy từ `contracts/` ở repo master (ví dụ `kids.v1`). Đổi DTO thì sửa contract trước.

### 13.5 Ánh xạ cấu trúc hiện tại của `services/fe` (khi migrate)

| Hiện tại | Đích |
|---|---|
| `components/kids/*` + `lib/kids/*` | `features/kids/{components,scene,hooks,lib,views}/` + `index.ts` |
| `lib/kids/api.ts`, `lib/api/portfolioApi.ts` | `shared/api/kids/kidsApi.ts`, `shared/api/portfolio/portfolioApi.ts` |
| `lib/kids/useReducedMotion.ts`, `lib/kids/webgl.ts`, `lib/performance/*` | `shared/hooks/`, `shared/three/` (không riêng của kids) |
| `components/kids/KidsShell.tsx` | `app/kids/layout.tsx` dùng `KidsShell` export từ `@/features/kids` |
| `components/experience`, `navigation`, `panels` + `context/PortfolioDataContext` + `data/` + `types/portfolio.ts` | `features/portfolio/{scene,components,lib,types.ts}` |
| `components/neobrutalism/*` | `features/<tên-trang>/components/` (hoặc xóa nếu không còn route dùng) |
| `app/v2/`, `components/v2/*V2.tsx` | Anti-pattern mục 12: chọn một bản, xóa bản kia; cần song song thì flag trong `shared/config` |
| `components/ui/*` | `shared/ui/` |
| `tests/kids/*.test.ts` | Colocate cạnh file trong `features/kids/lib/` (mục 9) |
| `out/`, `.pnpm-store/` | Artefact — đã gitignore, xóa khỏi ổ đĩa, không tham chiếu |

Thứ tự migrate: một feature mỗi commit (`kids` → `portfolio` → dọn `v2`/`neobrutalism`), chạy `typecheck && test && build` sau mỗi bước. Chỉ di chuyển file + sửa import trong commit migrate, không kèm đổi logic.

### 13.6 ESLint cho Next

Dùng `next lint` (`eslint-config-next`) + rule của mục 4 (cả phần giới hạn kích thước; với `.eslintrc` cần khai báo `plugins: ['@typescript-eslint']` trong override thì rule `@typescript-eslint/*` mới chạy), thêm:

```js
// .eslintrc / overrides
{ files: ['src/shared/**'], rules: { 'no-restricted-imports': ['error', { patterns: ['@/features/*', '@/app/*'] }] } },
{ files: ['src/features/**'], rules: { 'no-restricted-imports': ['error', { patterns: ['@/app/*', '@/features/*/*'] }] } },
```

**Style của `services/fe`:** Neo-brutalism là design system mặc định (utility `neo-*` trong `src/styles/tailwind.css`, mẫu ở `src/features/home/components/Neo*.tsx`). Rule `no-restricted-syntax` trong `.eslintrc.cjs` áp cho mọi `src/**/*.tsx` và chặn class bóng mờ, `rounded-3xl`, gradient, blur, palette Tailwind. Chỉ `features/portfolio` (trang 3D pastel) được miễn. Feature mới mặc định theo neo-bruta.

### 13.7 Checklist feature mới (Next)

1. `src/features/<f>/` có `index.ts` và View (đánh dấu `'use client'` nếu cần).
2. API: `src/shared/api/<resource>/` + test; contract trong `contracts/` của repo master.
3. Path vào `shared/config/paths.ts`; tạo `src/app/<segment>/page.tsx` chỉ render View (+ `layout.tsx` nếu có chrome riêng).
4. Biến môi trường mới → `.env.example` ở repo master (`NEXT_PUBLIC_*` nếu client cần).
5. `pnpm typecheck && pnpm lint && pnpm test && pnpm build` xanh (lint gồm giới hạn kích thước và style).
