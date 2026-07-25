import { useBookFile } from '../hooks/useBookFile';
import { useObjectUrl } from '../hooks/useObjectUrl';

interface Props {
  uuid: string;
  title: string;
}

export function BookCover({ uuid, title }: Props) {
  const file = useBookFile(uuid);
  const coverUrl = useObjectUrl(file?.coverBlob);

  if (!coverUrl) {
    return (
      <div className="book-cover book-cover--placeholder" aria-label={title}>
        <span className="book-cover__icon">📄</span>
      </div>
    );
  }

  return <img className="book-cover" src={coverUrl} alt={`Cover of ${title}`} loading="lazy" />;
}
