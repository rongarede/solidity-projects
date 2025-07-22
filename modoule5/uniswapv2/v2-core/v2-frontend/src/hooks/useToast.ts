'use client'

import { useState, useCallback } from 'react'
import { Toast, ToastType } from '../components/ui/Toast'

export function useToast() {
  const [toasts, setToasts] = useState<Toast[]>([])

  const addToast = useCallback((
    type: ToastType,
    title: string,
    message: string,
    duration?: number
  ) => {
    const id = Math.random().toString(36).substring(2, 9)
    const newToast: Toast = {
      id,
      type,
      title,
      message,
      duration
    }

    setToasts(prevToasts => [...prevToasts, newToast])
    return id
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts(prevToasts => prevToasts.filter(toast => toast.id !== id))
  }, [])

  const showSuccess = useCallback((title: string, message: string, duration?: number) => {
    return addToast('success', title, message, duration)
  }, [addToast])

  const showError = useCallback((title: string, message: string, duration?: number) => {
    return addToast('error', title, message, duration)
  }, [addToast])

  const showWarning = useCallback((title: string, message: string, duration?: number) => {
    return addToast('warning', title, message, duration)
  }, [addToast])

  const showInfo = useCallback((title: string, message: string, duration?: number) => {
    return addToast('info', title, message, duration)
  }, [addToast])

  const clearAllToasts = useCallback(() => {
    setToasts([])
  }, [])

  return {
    toasts,
    addToast,
    removeToast,
    showSuccess,
    showError,
    showWarning,
    showInfo,
    clearAllToasts
  }
}