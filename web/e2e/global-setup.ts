import type { FullConfig } from '@playwright/test'

export default async function globalSetup(config: FullConfig): Promise<void> {
  const baseURL = config.projects[0]?.use.baseURL
  if (typeof baseURL !== 'string') throw new Error('E2E_BASE_URL을 확인하세요.')
  try {
    const response = await fetch(new URL('/api/health', baseURL), { signal: AbortSignal.timeout(3_000) })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  } catch (error) {
    throw new Error(`개발 서버를 먼저 실행하세요: dotnet watch run --launch-profile https 및 web/ 에서 npm run dev. (${error instanceof Error ? error.message : String(error)})`)
  }
}
