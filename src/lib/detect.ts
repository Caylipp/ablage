import type { ClipKind } from './types';

const COLOR = /^(#([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})|rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*(0|1|0?\.\d+)\s*)?\)|hsla?\(\s*\d{1,3}(deg)?\s*,\s*\d{1,3}%\s*,\s*\d{1,3}%\s*(,\s*(0|1|0?\.\d+)\s*)?\))$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i;
const LINK = /^(https?:\/\/|www\.)[^\s]+$|^[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|de|org|net|io|dev|app|at|ch|eu|co|me|info)(\/[^\s]*)?$/i;
const PHONE = /^\+?[\d\s()/-]{6,20}$/;
// Typische Code-Merkmale: Klammern/Semikolons am Zeilenende, Schlüsselwörter, Einrückung
const CODE_HINTS = [
  /[{};]\s*$/m,
  /^\s*(const|let|var|function|import|export|return|def|class|if|for|while|public|private|#include|SELECT|FROM)\b/m,
  /=>|::|\(\)\s*\{|<\/?[a-z][\w-]*[^>]*>/,
];

export function detectKind(raw: string): ClipKind {
  const text = raw.trim();
  if (!text) return 'text';
  const single = !text.includes('\n');
  if (single && COLOR.test(text)) return 'color';
  if (single && EMAIL.test(text)) return 'email';
  if (single && LINK.test(text)) return 'link';
  if (single && PHONE.test(text) && (text.match(/\d/g)?.length ?? 0) >= 6) return 'phone';
  const hits = CODE_HINTS.filter((r) => r.test(text)).length;
  if (hits >= 2 || (hits >= 1 && !single)) return 'code';
  return 'text';
}

/** Macht aus „www.x.de“ eine öffnungsfähige URL. */
export function toUrl(text: string): string {
  const t = text.trim();
  return /^https?:\/\//i.test(t) ? t : `https://${t}`;
}

export function domainOf(text: string): string {
  return toUrl(text).replace(/^https?:\/\//i, '').replace(/^www\./i, '').split(/[/?#]/)[0];
}

