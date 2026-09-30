<script setup lang="ts">
import AppBadge from '../design-system/AppBadge.vue'
import AppButton from '../design-system/AppButton.vue'
import AppInput from '../design-system/AppInput.vue'
import EmptyState from '../design-system/EmptyState.vue'
import Skeleton from '../design-system/Skeleton.vue'
</script>

<template><section><div class="page-title"><div><h1>Styleguide</h1><p>SPA 공통 토큰과 기본 UI 상태를 확인합니다.</p></div></div><div class="style-grid"><article class="panel"><h2>색상</h2><div class="swatch primary">Primary</div><div class="swatch danger">Danger</div><div class="swatch surface">Surface</div></article><article class="panel"><h2>버튼</h2><div class="actions"><AppButton>기본</AppButton><AppButton variant="secondary">보조</AppButton><AppButton variant="danger">삭제</AppButton><AppButton disabled>비활성</AppButton></div></article><article class="panel"><h2>입력</h2><label>텍스트<AppInput placeholder="입력값" /></label></article><article class="panel"><h2>상태</h2><div class="actions"><AppBadge status="DRAFT" /><AppBadge status="REVIEW" /><AppBadge status="APPROVED" /><AppBadge status="PUBLISHED" /><AppBadge status="OBSOLETE" /></div></article><article class="panel"><h2>로딩</h2><Skeleton height="1.4rem" /><Skeleton width="72%" /></article><article class="panel"><EmptyState title="표시할 항목이 없습니다" description="필터를 바꾸거나 새 항목을 추가하세요." /></article></div></section></template>
