<script setup>
import { ref } from 'vue'

const emit = defineEmits(['admin-register-success', 'go-admin-login'])
const username = ref('')
const password = ref('')
const confirmPassword = ref('')
const isLoading = ref(false)
const errorMsg = ref('')

function handleRegister() {
  if (!username.value || !password.value || !confirmPassword.value) {
    errorMsg.value = '请填写完整信息'
    return
  }
  if (password.value !== confirmPassword.value) {
    errorMsg.value = '两次输入的密码不一致'
    return
  }
  errorMsg.value = ''
  isLoading.value = true
  
  fetch('http://localhost:3000/api/admin/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  })
  .then(res => res.json().then(data => ({ status: res.status, ok: res.ok, data })))
  .then(({ status, ok, data }) => {
    if (!ok) {
      errorMsg.value = data.error || '注册失败'
    } else {
      emit('admin-register-success')
    }
  })
  .catch(err => {
    errorMsg.value = '网络错误，无法连接到服务器'
  })
  .finally(() => {
    isLoading.value = false
  })
}
</script>

<template>
  <div class="auth-container">
    <div class="auth-card">
      <div class="auth-header">
        <div class="logo-placeholder">🏛️</div>
        <h2>申请管理员权限</h2>
        <p>配置您的最高权限账号</p>
      </div>
      
      <form class="auth-form" @submit.prevent="handleRegister">
        <label class="auth-field">
          <span>管理员账号</span>
          <input v-model="username" type="text" placeholder="设置您的管理员账号" />
        </label>
        
        <label class="auth-field">
          <span>密码</span>
          <input v-model="password" type="password" placeholder="设置高强度密码" />
        </label>

        <label class="auth-field">
          <span>确认密码</span>
          <input v-model="confirmPassword" type="password" placeholder="再次输入密码" />
        </label>

        <p v-if="errorMsg" class="auth-error">{{ errorMsg }}</p>

        <button type="submit" class="auth-btn" :disabled="isLoading">
          <span v-if="isLoading" class="spinner-small"></span>
          {{ isLoading ? '授权中...' : '申 请 权 限' }}
        </button>
      </form>

      <div class="auth-footer">
        已有管理员账号？ <a href="#" @click.prevent="emit('go-admin-login')">返回管理登录</a>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at bottom right, #271a1a, #0d0909);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  padding: 1rem;
}

.auth-card {
  background: rgba(39, 26, 26, 0.7);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 215, 0, 0.2);
  padding: 2.5rem 2rem;
  border-radius: 20px;
  width: 100%;
  max-width: 400px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.8);
  animation: slideUp 0.5s ease-out forwards;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.auth-header {
  text-align: center;
  margin-bottom: 2rem;
}

.logo-placeholder {
  font-size: 3rem;
  margin-bottom: 0.5rem;
  animation: float 3s ease-in-out infinite;
  text-shadow: 0 0 20px rgba(255, 215, 0, 0.5);
}

@keyframes float {
  0% { transform: translateY(0px); }
  50% { transform: translateY(-10px); }
  100% { transform: translateY(0px); }
}

.auth-header h2 {
  margin: 0;
  color: #ffd700;
  font-size: 1.5rem;
  font-weight: 600;
}

.auth-header p {
  color: #cda880;
  margin: 0.5rem 0 0;
  font-size: 0.9rem;
}

.auth-field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1.25rem;
}

.auth-field span {
  color: #ebd7bd;
  font-size: 0.85rem;
  font-weight: 500;
}

.auth-field input {
  background: rgba(20, 10, 10, 0.5);
  border: 1px solid rgba(255, 215, 0, 0.2);
  padding: 0.75rem 1rem;
  border-radius: 8px;
  color: #fff;
  font-size: 1rem;
  outline: none;
  transition: all 0.2s;
}

.auth-field input:focus {
  border-color: #ffd700;
  box-shadow: 0 0 0 2px rgba(255, 215, 0, 0.2);
}

.auth-btn {
  background: linear-gradient(135deg, #b8860b, #d4af37);
  color: #fff;
  border: none;
  padding: 0.875rem;
  width: 100%;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.5rem;
  margin-top: 1.5rem;
  text-shadow: 0 1px 2px rgba(0,0,0,0.5);
}

.auth-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px -10px rgba(255, 215, 0, 0.6);
}

.auth-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.auth-error {
  color: #ff4d4f;
  font-size: 0.85rem;
  margin: -0.5rem 0 1rem;
  text-align: center;
}

.auth-footer {
  margin-top: 2rem;
  text-align: center;
  color: #cda880;
  font-size: 0.9rem;
}

.auth-footer a {
  color: #ffd700;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.2s;
}

.auth-footer a:hover {
  color: #fffacd;
}

.spinner-small {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
