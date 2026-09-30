<script setup lang="ts">
import { computed } from 'vue'
import { useSessionStore } from '../stores/session'
import AppIcon from '../design-system/AppIcon.vue'

const session = useSessionStore()
const menus = computed(() => new Set(session.user?.MENUS.map(menu => menu.KEY) ?? []))
const hasMenu = (key: string) => menus.value.has(key)
</script>

<template>
  <section class="dashboard">
    <div class="page-title">
      <div>
        <h1>안녕하세요, {{ session.user?.FULL_NAME }} 님</h1>
        <p>시스템 매뉴얼을 작성하고 검토한 뒤 표준 서식의 PDF 로 배포합니다.</p>
      </div>
      <RouterLink class="button" to="/manual">매뉴얼 목록 열기</RouterLink>
    </div>

    <div class="dashboard-hero">
      <span>Knowledge Base</span>
      <h2>문서 구조는 템플릿으로, 내용은 담당 팀이</h2>
      <p>목차에 지정된 담당 팀만 해당 내용을 편집할 수 있습니다. 작성이 끝나면 미리보기에서 실제 인쇄 크기로 확인하고 PDF 로 내려받습니다.</p>
    </div>

    <div class="dashboard-tiles">
      <RouterLink class="dashboard-tile" to="/manual"><AppIcon name="book-open-page-variant-outline" /><strong>매뉴얼</strong><span>문서를 만들고 목차와 본문을 작성합니다.</span></RouterLink>
      <RouterLink v-if="hasMenu('admin.section-template')" class="dashboard-tile" to="/admin/section-template"><AppIcon name="format-list-bulleted-square" /><strong>목차 템플릿</strong><span>Label · Cooling 조합별 표준 목차를 정의합니다.</span></RouterLink>
      <RouterLink v-if="hasMenu('admin.user')" class="dashboard-tile" to="/admin/user"><AppIcon name="account-group-outline" /><strong>사용자 관리</strong><span>계정 등록·수정과 역할·로그인 상태를 관리합니다.</span></RouterLink>
      <RouterLink v-if="hasMenu('admin.code')" class="dashboard-tile" to="/admin/code"><AppIcon name="code-tags" /><strong>공통 코드</strong><span>표지 문구·로고 등 공통 설정 값을 관리합니다.</span></RouterLink>
      <RouterLink v-if="hasMenu('admin.setting')" class="dashboard-tile" to="/admin/setting"><AppIcon name="email-cog-outline" /><strong>시스템 설정</strong><span>메일 발송(SMTP) 등 운영 설정을 다룹니다.</span></RouterLink>
    </div>
  </section>
</template>
