import { describe, expect, it } from 'vitest'
import { normalizeTable, renumberTable, toTableHtml } from '../src/features/editor/table'

describe('table block helpers', () => {
  it('normalizes malformed table data into an editable grid', () => {
    expect(normalizeTable('{')).toMatchObject({
      head: ['No.', 'Title', 'Function'],
      rows: [
        ['1', '', ''],
        ['2', '', ''],
      ],
    })
    expect(
      normalizeTable(JSON.stringify({ head: ['A', 'B'], rows: [['one']], align: ['center', 'invalid'], widths: [25] })),
    ).toEqual({
      head: ['A', 'B'],
      align: ['center', 'left'],
      widths: [25, 0],
      rich: [false, false],
      rows: [['one', '']],
    })
  })

  it('encodes cell content before generating preview HTML', () => {
    const html = toTableHtml({ head: ['<title>'], align: ['left'], widths: [100], rows: [['A & B\n"quoted"']] })
    expect(html).toContain('&lt;title&gt;')
    expect(html).toContain('A &amp; B<br>&quot;quoted&quot;')
  })

  it('preserves HTML only in rich cells', () => {
    const html = toTableHtml({
      head: ['Title', 'Function'],
      align: ['left', 'left'],
      widths: [30, 70],
      rich: [false, true],
      rows: [['<title>', '<p><strong>formatted</strong></p>']],
    })
    expect(html).toContain('&lt;title&gt;')
    expect(html).toContain('<p><strong>formatted</strong></p>')
  })

  it('renumbers a No. column after rows change', () => {
    const table = normalizeTable(
      JSON.stringify({
        head: ['No.', 'Title'],
        rows: [
          ['9', 'first'],
          ['3', 'second'],
        ],
      }),
    )
    table.rows.splice(0, 1)
    renumberTable(table)
    expect(table.rows).toEqual([['1', 'second']])
  })
})
