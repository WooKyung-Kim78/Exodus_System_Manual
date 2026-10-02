export type CellAlign = 'left' | 'center' | 'right'

export interface TableState {
  head: string[]
  align: CellAlign[]
  widths: number[]
  rich: boolean[]
  rows: string[][]
}

const alignments = new Set<CellAlign>(['left', 'center', 'right'])

export function newTable(): TableState {
  return {
    head: ['No.', 'Title', 'Function'],
    align: ['center', 'center', 'left'],
    widths: [10, 25, 65],
    rich: [false, false, true],
    rows: [
      ['1', '', ''],
      ['2', '', ''],
    ],
  }
}

export function normalizeTable(json?: string): TableState {
  let value: unknown
  try {
    value = json ? JSON.parse(json) : null
  } catch {
    value = null
  }
  if (
    !value ||
    typeof value !== 'object' ||
    !Array.isArray((value as TableState).head) ||
    !(value as TableState).head.length
  )
    return newTable()
  const source = value as { head: unknown[]; align?: unknown[]; widths?: unknown[]; rich?: unknown[]; rows?: unknown[] }
  const text = (item: unknown) => (item == null ? '' : String(item))
  const head = source.head.map(text)
  const rows = Array.isArray(source.rows)
    ? source.rows.map((row) => head.map((_, index) => text(Array.isArray(row) ? row[index] : undefined)))
    : []
  return {
    head,
    align: head.map((_, index) => {
      const align = source.align?.[index]
      return alignments.has(align as CellAlign) ? (align as CellAlign) : 'left'
    }),
    widths: head.map((_, index) => Number(source.widths?.[index]) || 0),
    rich: head.map(
      (name, index) => source.rich?.[index] === true || (!source.rich && name.trim().toUpperCase() === 'FUNCTION'),
    ),
    rows: rows.length ? rows : [head.map(() => '')],
  }
}

function cellHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replace(/\r?\n/g, '<br>')
}

export function toTableHtml(table: TableState): string {
  const cols = table.widths.some((width) => width > 0)
    ? `<colgroup>${table.widths.map((width) => (width > 0 ? `<col style="width:${width}%">` : '<col>')).join('')}</colgroup>`
    : ''
  const head = `<thead><tr>${table.head.map((cell, index) => `<th style="text-align:${table.align[index]}">${cellHtml(cell)}</th>`).join('')}</tr></thead>`
  const rows = `<tbody>${table.rows.map((row) => `<tr>${row.map((cell, index) => `<td style="text-align:${table.align[index]}">${table.rich?.[index] ? cell : cellHtml(cell)}</td>`).join('')}</tr>`).join('')}</tbody>`
  return `<table>${cols}${head}${rows}</table>`
}
