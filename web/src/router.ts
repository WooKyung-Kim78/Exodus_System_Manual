import { createRouter, createWebHistory } from 'vue-router'
import { useSessionStore } from './stores/session'
import AppShell from './components/AppShell.vue'
import SignInPage from './pages/SignInPage.vue'
import ErrorPage from './pages/ErrorPage.vue'
import ManualListPage from './pages/ManualListPage.vue'
import ManualDetailPage from './pages/ManualDetailPage.vue'
import PreviewPage from './pages/PreviewPage.vue'
import PlaceholderPage from './pages/PlaceholderPage.vue'
import CodePage from './pages/admin/CodePage.vue'
import UserPage from './pages/admin/UserPage.vue'
import MailSettingPage from './pages/admin/MailSettingPage.vue'
import StyleguidePage from './pages/StyleguidePage.vue'
import DashboardPage from './pages/DashboardPage.vue'

const protectedRoutes = [
  { path: '/', component: DashboardPage, meta: { menuKey: 'dashboard' } },
  { path: '/manual', component: ManualListPage, meta: { menuKey: 'manual' } },
  { path: '/manual/detail', component: ManualDetailPage, meta: { menuKey: 'manual', hidePageHeader: true } },
  { path: '/manual/preview', component: PreviewPage, meta: { menuKey: 'manual' } },
  { path: '/editor', component: () => import('./pages/EditorPage.vue'), meta: { menuKey: 'manual' } },
  { path: '/dev/styleguide', component: StyleguidePage, meta: { developmentOnly: true } },
  { path: '/admin/user', component: UserPage, meta: { menuKey: 'admin.user' } },
  { path: '/admin/code', component: CodePage, meta: { menuKey: 'admin.code' } },
  { path: '/admin/setting', component: MailSettingPage, meta: { menuKey: 'admin.setting' } },
  { path: '/admin/section-template', component: () => import('./pages/admin/SectionTemplatePage.vue'), meta: { menuKey: 'admin.section-template' } },
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
    if (!session.loaded) await session.load()
  } catch {
    session.clear()
    return { path: '/auth/sign-in', query: { returnUrl: to.fullPath } }
  }
  if (to.meta.developmentOnly && !session.bootstrap?.isDevelopment) return '/auth/error404'
  const menuKey = to.meta.menuKey as string | undefined
  return !menuKey || session.user!.MENUS.some(menu => menu.KEY === menuKey) ? true : '/auth/error403'
})
