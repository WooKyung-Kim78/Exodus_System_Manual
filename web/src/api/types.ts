export interface ApiResponse<T> { success: boolean; data: T; message?: string }
export interface CurrentUser { USER_ID: string; FULL_NAME: string; EMAIL: string; ROLE: string; DIVISION: string; TEAM: string }
export interface BootstrapData { isDevelopment: boolean }
export interface ManualListItem { M_ID: string; MODEL_NAME: string; JOB_NUMBER?: string; DOC_NUM?: string; REVISION: string; STATUS: string; REQUESTER_NAME?: string; REG_DT: string }
export interface ManualHeader extends ManualListItem { PAGE_SIZE: 'A4' | 'LETTER'; LABEL?: string; COOLING?: string; OPTION_TEXT?: string; DOC_VERSION?: string }
export interface ManualSection { SEC_ID: number; SEC_NO?: string; TITLE: string; SEC_LEVEL: number; SEC_TYPE?: string; CAN_EDIT_SEC?: string; ASSIGNED_TEAM?: string }
