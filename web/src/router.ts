import { createRouter, createWebHistory } from 'vue-router'
import { initializeCsrf } from './api/client'
import { useSessionStore } from './stores/session'
import AppShell from './components/AppShell.vue'
import SignInPage from './pages/SignInPage.vue'
import ErrorPage from './pages/ErrorPage.vue'
import ManualListPage from './pages/ManualListPage.vue'
import ManualDetailPage from './pages/ManualDetailPage.vue'
import PreviewPage from './pages/PreviewPage.vue'
import PlaceholderPage from './pages/PlaceholderPage.vue'
import CodePage from './pages/CodePage.vue'
import UserPage from './pages/UserPage.vue'
import MailSettingPage from './pages/MailSettingPage.vue'
import StyleguidePage from './pages/StyleguidePage.vue'

const protectedRoutes = [
  { path: '/', component: ManualListPage },
  { path: '/manual', component: ManualListPage },
  { path: '/manual/detail', component: ManualDetailPage },
  { path: '/manual/preview', component: PreviewPage },
  { path: '/editor', component: () => import('./pages/EditorPage.vue') },
  { path: '/dev/styleguide', component: StyleguidePage, meta: { developmentOnly: true } },
  { path: '/admin/user', component: UserPage, meta: { roles: ['ADMIN'] } },
  { path: '/admin/code', component: CodePage, meta: { roles: ['ADMIN', 'SUPPORTER'] } },
  { path: '/admin/setting', component: MailSettingPage, meta: { roles: ['ADMIN', 'SUPPORTER'] } },
  { path: '/admin/section-template', component: () => import('./pages/SectionTemplatePage.vue'), meta: { roles: ['ADMIN'] } },
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
  if (to.meta.developmentOnly && !session.bootstrap?.isDevelopment) return '/auth/error404'
  return !roles || roles.includes(session.user!.ROLE) ? true : '/auth/error403'
})
