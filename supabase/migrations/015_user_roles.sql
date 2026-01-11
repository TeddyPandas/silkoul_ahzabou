-- Create User Role Enum
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'SUPER_ADMIN');

-- Add role column to profiles
ALTER TABLE public.profiles 
ADD COLUMN role user_role NOT NULL DEFAULT 'USER';

-- Create helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('ADMIN', 'SUPER_ADMIN')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS for Wazifa Gatherings (Example of securing an admin table)
-- We already have "Authenticated Access" policy, let's refine it for DELETE/UPDATE
-- (Assuming we want to lock down DELETE/UPDATE to Admins only, except for Creator on PENDING)

-- Policy: Admin Full Access
CREATE POLICY "Admin Full Access"
ON public.wazifa_gatherings
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Policy: Super Admin can update roles
-- This requires a specific policy on 'profiles' table. 
-- Currently profiles is usually "Users can update own".
-- We need: "Super Admin can update ANY profile's role".

CREATE POLICY "Super Admin Update Roles"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'SUPER_ADMIN'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'SUPER_ADMIN'
  )
);
