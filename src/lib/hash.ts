/** FNV-1a (32 Bit) – schnell genug auch für Base64-Bilder im MB-Bereich. */
export function fnv1a(input: string): string {
  let h = 0x811c9dc5;
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0).toString(16).padStart(8, '0');
}

export function clipHash(kind: 'text' | 'image', content: string): string {
  return `${kind}:${content.length}:${fnv1a(content)}`;
}

export function newId(now = Date.now()): string {
  return `${now.toString(36)}${Math.random().toString(36).slice(2, 8)}`;
}
