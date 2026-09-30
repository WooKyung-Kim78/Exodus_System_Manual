import { describe, expect, it } from 'vitest'
import { getManualStatus } from '../src/features/manual/status'

describe('getManualStatus', () => {
  it('known status returns the configured Korean label and tone', () => {
    expect(getManualStatus('PUBLISHED')).toEqual({ label: '발행됨', tone: 'info' })
  })

  it('unknown status remains visible with a neutral tone', () => {
    expect(getManualStatus('UNKNOWN')).toEqual({ label: 'UNKNOWN', tone: 'neutral' })
  })
})
