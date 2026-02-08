-- Add is_finished column to campaigns table
ALTER TABLE public.campaigns 
ADD COLUMN is_finished boolean DEFAULT false;

-- Comment on column
COMMENT ON COLUMN public.campaigns.is_finished IS 'Indicates if the campaign has been manually finished by the creator';
