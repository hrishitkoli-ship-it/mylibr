import { HashRouter, Routes, Route } from 'react-router-dom';
import { BookshelfPage } from './pages/BookshelfPage';
import { ReaderPage } from './pages/ReaderPage';

export default function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/" element={<BookshelfPage />} />
        <Route path="/read/:uuid" element={<ReaderPage />} />
      </Routes>
    </HashRouter>
  );
}
