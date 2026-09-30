export interface ApiResponse<T> { success: boolean; data: T; message?: string }
export interface MenuLink { KEY: string; PATH: string }
export interface CurrentUser { USER_ID: string; FULL_NAME: string; EMAIL: string; ROLE: string; DIVISION: string; TEAM: string; MENUS: MenuLink[]; CAPABILITIES: { CAN_CREATE_MANUAL: boolean } }
export interface HeadingStyle { size: number; color: string; bold: boolean; underline: boolean }
export interface BodyFont { code: string; name: string }
export interface BootstrapData { isDevelopment: boolean; headingStyles: Record<string, HeadingStyle>; bodyFonts: BodyFont[] }
export interface ManualListItem { M_ID: string; MODEL_NAME: string; JOB_NUMBER?: string; DOC_NUM?: string; OPTION_TEXT?: string; REVISION: string; STATUS: string; REQUESTER_NAME?: string; MY_ROLE?: string; REG_DT: string }
export interface ManualHeader extends ManualListItem { PAGE_SIZE: 'A4' | 'LETTER'; LABEL?: string; COOLING?: string; OPTION_TEXT?: string; DOC_VERSION?: string; PROCESS_ID?: string; COVER_IMAGE_PATH?: string; HEADING_STYLE_JSON?: string; BODY_FONT?: string; BODY_LINE_HEIGHT?: number; BODY_LETTER_SPACING?: number }
export interface ManualSection { SEC_ID: number; SEC_NO?: string; TITLE: string; SEC_LEVEL: number; SEC_TYPE?: 'NORMAL' | 'PAGEBREAK'; CAN_EDIT_SEC?: string; ASSIGNED_TEAM?: string; TITLE_ALIGN?: 'LEFT' | 'CENTER' | 'RIGHT'; SHOW_IN_TOC?: 'Y' | 'N'; TITLE_UNDERLINE?: 'Y' | 'N'; STYLE_JSON?: string; BLOCK_CNT?: number }
export interface DatasheetOption { D_ID: string; NAME: string; TITLE?: string; DS_VERSION?: string }
export interface NotifyRecipient { USER_ID: string; FULL_NAME: string; MEMBER_ROLE: string; EMAIL_ADDRESS?: string; SECTION_CNT: number; ASSIGNED_SECTIONS?: string }
export interface TeamOption { DIVISION: string; TEAM: string }
export interface SectionTemplateOption { TPL_ID: number; SEC_NO?: string; TITLE: string; SEC_LEVEL: number; ASSIGNED_TEAM?: string; SEC_TYPE: 'NORMAL' | 'PAGEBREAK'; IS_MANDATORY: 'Y' | 'N'; IS_ADDED: 'Y' | 'N' }
export interface SectionHistoryItem { HIS_ID: number; SEC_ID?: number; ELE_ID?: number; ACTION: string; FIELD_NAME?: string; BEFORE_VALUE?: string; AFTER_VALUE?: string; REG_NAME: string; REG_TEAM?: string; REG_DT: string }
