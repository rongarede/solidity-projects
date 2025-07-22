'use client'

import { usePathname } from 'next/navigation'
import { useState, useEffect } from 'react'

export function useSafePathname() {
  const pathname = usePathname()
  const [safePath, setSafePath] = useState('/')

  useEffect(() => {
    setSafePath(pathname)
  }, [pathname])

  return safePath
}