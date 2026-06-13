import { SupabaseClient } from 'jsr:@supabase/supabase-js@2'

export async function requireAuth(supabaseClient: SupabaseClient) {
  const { data: { user }, error } = await supabaseClient.auth.getUser()
  if (error || !user) {
    throw new Error('Unauthorized')
  }
  return user
}

export function requireString(value: any, name: string): string {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`Missing or invalid required field: ${name}`)
  }
  return value.trim()
}
