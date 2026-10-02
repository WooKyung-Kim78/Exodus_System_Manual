<script setup lang="ts">
import { ref } from 'vue'
import AppBadge from '../design-system/AppBadge.vue'
import AppButton from '../design-system/AppButton.vue'
import AppDrawer from '../design-system/AppDrawer.vue'
import AppInput from '../design-system/AppInput.vue'
import AppTable from '../design-system/AppTable.vue'
import AppTabs from '../design-system/AppTabs.vue'
import AppToast from '../design-system/AppToast.vue'
import AppTooltip from '../design-system/AppTooltip.vue'
import EmptyState from '../design-system/EmptyState.vue'
import Skeleton from '../design-system/Skeleton.vue'

const drawerOpen = ref(false)
const selectedTab = ref('overview')
const toastOpen = ref(false)
const tabs = [
  { id: 'overview', label: '개요' },
  { id: 'history', label: '이력' },
  { id: 'disabled', label: '비활성', disabled: true },
]
</script>

<template>
  <section>
    <div class="page-title">
      <div>
        <h1>Styleguide</h1>
        <p>SPA 공통 토큰과 기본 UI 상태를 확인합니다.</p>
      </div>
    </div>
    <div class="style-grid">
      <article class="panel">
        <h2>색상</h2>
        <div class="swatch primary">Primary</div>
        <div class="swatch danger">Danger</div>
        <div class="swatch surface">Surface</div>
      </article>
      <article class="panel">
        <h2>버튼</h2>
        <div class="actions">
          <AppButton>기본</AppButton><AppButton variant="secondary">보조</AppButton
          ><AppButton variant="danger">삭제</AppButton><AppButton disabled>비활성</AppButton>
        </div>
      </article>
      <article class="panel">
        <h2>입력</h2>
        <label>텍스트<AppInput placeholder="입력값" /></label>
      </article>
      <article class="panel">
        <h2>상태</h2>
        <div class="actions">
          <AppBadge status="DRAFT" /><AppBadge status="REVIEW" /><AppBadge status="APPROVED" /><AppBadge
            status="PUBLISHED"
          /><AppBadge status="OBSOLETE" />
        </div>
      </article>
      <article class="panel">
        <h2>로딩</h2>
        <Skeleton height="1.4rem" /><Skeleton width="72%" />
      </article>
      <article class="panel">
        <EmptyState title="표시할 항목이 없습니다" description="필터를 바꾸거나 새 항목을 추가하세요." />
      </article>
      <article class="panel">
        <h2>탭</h2>
        <AppTabs v-model="selectedTab" :items="tabs" />
        <p>선택됨: {{ selectedTab }}</p>
      </article>
      <article class="panel">
        <h2>오버레이</h2>
        <div class="actions">
          <AppButton @click="drawerOpen = true">Drawer 열기</AppButton
          ><AppTooltip text="짧은 도움말입니다."><AppButton variant="secondary">Tooltip</AppButton></AppTooltip
          ><AppButton variant="secondary" @click="toastOpen = true">Toast 표시</AppButton>
        </div>
      </article>
      <article class="panel">
        <h2>테이블</h2>
        <AppTable
          ><thead>
            <tr>
              <th>항목</th>
              <th>상태</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>예시 문서</td>
              <td>작성 중</td>
            </tr>
          </tbody>
          <template #footer><span>1–1 / 1</span></template></AppTable
        >
      </article>
    </div>
    <AppDrawer v-model:open="drawerOpen" title="Drawer 예시"
      ><p>화면 보조 작업을 위한 패널입니다.</p>
      <template #footer
        ><AppButton variant="secondary" @click="drawerOpen = false">닫기</AppButton></template
      ></AppDrawer
    ><AppToast v-model:open="toastOpen" message="작업이 완료되었습니다." type="success" />
  </section>
</template>
