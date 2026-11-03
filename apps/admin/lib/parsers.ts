/**
 * Extracts YouTube 11-char Video ID from various URL formats
 * (youtu.be, watch?v=, embed/, shorts/)
 */
export function extractYouTubeId(url: string): string | null {
  if (!url) return null;
  const cleaned = url.trim();
  const match = cleaned.match(
    /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})/
  );
  return match ? match[1] : null;
}

/**
 * Extracts Google Drive File ID from various sharing formats
 * (/file/d/{id}/view, ?id={id}, open?id={id})
 */
export function extractDriveFileId(url: string): string | null {
  if (!url) return null;
  const cleaned = url.trim();
  const match = cleaned.match(/(?:\/d\/|[?&]id=)([A-Za-z0-9_-]{10,})/);
  return match ? match[1] : null;
}

