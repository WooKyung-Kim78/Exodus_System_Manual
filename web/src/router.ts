import { createRouter, createWebHistory } from 'vue-router'
import { initializeCsrf } from './api/client'
import { useSessionStore } from './stores/session'
import AppShell from './components/AppShell.vue'
import SignInPage from './pages/SignInPage.vue'
import ErrorPage from './pages/ErrorPage.vue'
import ManualListPage from './pages/ManualListPage.vue'
import ManualDetailPage from './pages/ManualDetailPage.vue'
import PreviewPage from './pages/PreviewPage.vue'
import EditorPage from './pages/EditorPage.vue'
import PlaceholderPage from './pages/PlaceholderPage.vue'

const protectedRoutes = [
  { path: '/', component: ManualListPage },
  { path: '/manual', component: ManualListPage },
  { path: '/manual/detail', component: ManualDetailPage },
  { path: '/manual/preview', component: PreviewPage },
  { path: '/editor', component: EditorPage },
  { path: '/admin/user', component: PlaceholderPage, props: { title: '사용자 관리' }, meta: { roles: ['ADMIN'] } },
  { path: '/admin/code', component: PlaceholderPage, props: { title: '공통 코드 관리' }, meta: { roles: ['ADMIN', 'SUPPORTER'] } },
  { path: '/admin/setting', component: PlaceholderPage, props: { title: '메일 설정' }, meta: { roles: ['ADMIN', 'SUPPORTER'] } },
  { path: '/admin/section-template', component: PlaceholderPage, props: { title: '목차 템플릿 관리' }, meta: { roles: ['ADMIN'] } },
]

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/auth/sign-in', component: SignInPage, meta: { public: true } },
    { path: '/auth/error403', component: ErrorPage, props: { code: 403 }, meta: { public: true } },
    { path: '/auth/error404', component: ErrorPage, props: { code: 404 }, meta: { public: true } },
    { path: '/', component: AppShell, children: protectedRoutes },
    { path: '/:pathMatch(.*)*', redirect: '/auth/error404' },
  ],
})

router.beforeEach(async to => {
  if (to.meta.public) return true
  const session = useSessionStore()
  try {
    if (!session.loaded) { await initializeCsrf(); await session.load() }
  } catch {
    session.clear()
    return { path: '/auth/sign-in', query: { returnUrl: to.fullPath } }
  }
  const roles = to.meta.roles as string[] | undefined
  return !roles || roles.includes(session.user!.ROLE) ? true : '/auth/error403'
})
