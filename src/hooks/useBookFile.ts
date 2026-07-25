import { useEffect, useState } from 'react';
import { libraryRepository } from '../db/libraryRepository';
import type { BookFile } from '../types';

export function useBookFile(uuid: string | undefined): BookFile | undefined {
  const [file, setFile] = useState<BookFile | undefined>(undefined);

  useEffect(() => {
    let cancelled = false;
    if (!uuid) {
      setFile(undefined);
      return;
    }
    libraryRepository.getBookFile(uuid).then((f) => {
      if (!cancelled) setFile(f);
    });
    return () => {
      cancelled = true;
    };
  }, [uuid]);

  return file;
}
