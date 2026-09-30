import { describe, expect, it } from 'vitest'
import { normalizeTable, toTableHtml } from '../src/features/editor/table'

describe('table block helpers', () => {
  it('normalizes malformed table data into an editable grid', () => {
    expect(normalizeTable('{')).toMatchObject({ head: ['No.', 'Title', 'Function'], rows: [['1', '', ''], ['2', '', '']] })
    expect(normalizeTable(JSON.stringify({ head: ['A', 'B'], rows: [['one']], align: ['center', 'invalid'], widths: [25] }))).toEqual({ head: ['A', 'B'], align: ['center', 'left'], widths: [25, 0], rows: [['one', '']] })
  })

  it('encodes cell content before generating preview HTML', () => {
    const html = toTableHtml({ head: ['<title>'], align: ['left'], widths: [100], rows: [['A & B\n"quoted"']] })
    expect(html).toContain('&lt;title&gt;')
    expect(html).toContain('A &amp; B<br>&quot;quoted&quot;')
  })
})
