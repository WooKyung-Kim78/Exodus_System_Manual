export const manualStatuses = {
  DRAFT: { label: '작성 중', tone: 'neutral' },
  REVIEW: { label: '검토 중', tone: 'warning' },
  APPROVED: { label: '승인됨', tone: 'success' },
  PUBLISHED: { label: '발행됨', tone: 'info' },
  OBSOLETE: { label: '폐기됨', tone: 'danger' },
} as const

export type ManualStatus = keyof typeof manualStatuses

export function getManualStatus(status: string) {
  return manualStatuses[status as ManualStatus] ?? { label: status, tone: 'neutral' as const }
}
