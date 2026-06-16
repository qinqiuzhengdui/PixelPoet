<script setup>
import { ref } from 'vue'

const emit = defineEmits(['login-success', 'go-register'])
const username = ref('')
const password = ref('')
const isLoading = ref(false)
const errorMsg = ref('')

function handleLogin() {
  if (!username.value || !password.value) {
    errorMsg.value = '请输入用户名和密码'
    return
  }
  errorMsg.value = ''
  isLoading.value = true
  
  fetch('http://localhost:3000/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  })
  .then(res => res.json().then(data => ({ status: res.status, ok: res.ok, data })))
  .then(({ status, ok, data }) => {
    if (!ok) {
      errorMsg.value = data.error || '登录失败'
    } else {
      emit('login-success')
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
        <div class="logo-placeholder">✨</div>
        <h2>欢迎回来</h2>
        <p>登录 PixelPoet 开始生成拼豆图纸</p>
      </div>
      
      <form class="auth-form" @submit.prevent="handleLogin">
        <label class="auth-field">
          <span>用户名</span>
          <input v-model="username" type="text" placeholder="请输入用户名" />
        </label>
        
        <label class="auth-field">
          <span>密码</span>
          <input v-model="password" type="password" placeholder="请输入密码" />
        </label>

        <p v-if="errorMsg" class="auth-error">{{ errorMsg }}</p>

        <button type="submit" class="auth-btn" :disabled="isLoading">
          <span v-if="isLoading" class="spinner-small"></span>
          {{ isLoading ? '登录中...' : '登 录' }}
        </button>
      </form>

      <div class="auth-footer">
        还没有账号？ <a href="#" @click.prevent="emit('go-register')">立即注册</a>
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
  background: radial-gradient(circle at top left, #1e293b, #0f172a);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  padding: 1rem;
}

.auth-card {
  background: rgba(30, 41, 59, 0.7);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 2.5rem 2rem;
  border-radius: 20px;
  width: 100%;
  max-width: 400px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
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
}

@keyframes float {
  0% { transform: translateY(0px); }
  50% { transform: translateY(-10px); }
  100% { transform: translateY(0px); }
}

.auth-header h2 {
  margin: 0;
  color: #fff;
  font-size: 1.5rem;
  font-weight: 600;
}

.auth-header p {
  color: #94a3b8;
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
  color: #cbd5e1;
  font-size: 0.85rem;
  font-weight: 500;
}

.auth-field input {
  background: rgba(15, 23, 42, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 0.75rem 1rem;
  border-radius: 8px;
  color: #fff;
  font-size: 1rem;
  outline: none;
  transition: all 0.2s;
}

.auth-field input:focus {
  border-color: #6ee7b7;
  box-shadow: 0 0 0 2px rgba(110, 231, 183, 0.2);
}

.auth-btn {
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
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
}

.auth-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px -10px rgba(139, 92, 246, 0.6);
}

.auth-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.auth-error {
  color: #f87171;
  font-size: 0.85rem;
  margin: -0.5rem 0 1rem;
  text-align: center;
}

.auth-footer {
  margin-top: 2rem;
  text-align: center;
  color: #94a3b8;
  font-size: 0.9rem;
}

.auth-footer a {
  color: #6ee7b7;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.2s;
}

.auth-footer a:hover {
  color: #34d399;
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
