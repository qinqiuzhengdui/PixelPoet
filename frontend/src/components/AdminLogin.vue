<script setup>
import { ref } from 'vue'

const emit = defineEmits(['admin-login-success', 'go-admin-register', 'go-user-login'])
const username = ref('')
const password = ref('')
const isLoading = ref(false)
const errorMsg = ref('')

function handleLogin() {
  if (!username.value || !password.value) {
    errorMsg.value = '请输入管理员账号和密码'
    return
  }
  errorMsg.value = ''
  isLoading.value = true
  
  fetch('http://localhost:3000/api/admin/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  })
  .then(res => res.json().then(data => ({ status: res.status, ok: res.ok, data })))
  .then(({ status, ok, data }) => {
    if (!ok) {
      errorMsg.value = data.error || '登录失败'
    } else {
      emit('admin-login-success')
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
        <div class="logo-placeholder">👑</div>
        <h2>管理员入口</h2>
        <p>专属权限，掌控全局</p>
      </div>
      
      <form class="auth-form" @submit.prevent="handleLogin">
        <label class="auth-field">
          <span>管理员账号</span>
          <input v-model="username" type="text" placeholder="请输入管理员账号" />
        </label>
        
        <label class="auth-field">
          <span>管理员密码</span>
          <input v-model="password" type="password" placeholder="请输入密码" />
        </label>

        <p v-if="errorMsg" class="auth-error">{{ errorMsg }}</p>

        <button type="submit" class="auth-btn" :disabled="isLoading">
          <span v-if="isLoading" class="spinner-small"></span>
          {{ isLoading ? '身份核验中...' : '尊 享 登 录' }}
        </button>
      </form>

      <div class="auth-footer">
        还不是管理员？ <a href="#" @click.prevent="emit('go-admin-register')">申请权限</a>
        <br/><br/>
        <a href="#" class="back-link" @click.prevent="emit('go-user-login')">← 返回普通用户登录</a>
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
  background: radial-gradient(circle at top left, #271a1a, #0d0909);
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

.back-link {
  color: #94a3b8 !important;
  font-size: 0.8rem;
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
