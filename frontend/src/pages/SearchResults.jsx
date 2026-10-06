import { useState, useEffect } from 'react';
import RouteCard from '../components/RouteCard';
import SearchCard from '../components/SearchCard';
import { api } from '../services/api';
import { LoadingState, EmptyState, ErrorState } from '../components/States';

export default function SearchResults({
  searchParams,
  onSearch,
  onSelectRoute,
  onTrackBus
}) {
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let isMounted = true;
    async function fetchResults() {
      setLoading(true);
      setError(null);
      try {
        const data = await api.searchRoutes(
          searchParams.from || '',
          searchParams.to || ''
        );
        if (isMounted) {
          setResults(data);
        }
      } catch (err) {
        if (isMounted) {
          setError('Failed to fetch route search results.');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    fetchResults();

    return () => {
      isMounted = false;
    };
  }, [searchParams]);

  return (
    <div className="search-results-page">
      <div className="search-header-container">
        <SearchCard
          onSearch={onSearch}
          initialFrom={searchParams.from || ''}
          initialTo={searchParams.to || ''}
        />
      </div>

      <div className="results-content-area">
        <div className="results-title-bar">
          <h2>
            {searchParams.from || searchParams.to
              ? `Routes: ${searchParams.from || 'Any'} → ${searchParams.to || 'Any'}`
              : 'All TMT Bus Routes'}
          </h2>
          <span className="results-count-badge">
            {loading ? 'Searching...' : `${results.length} ${results.length === 1 ? 'route' : 'routes'} found`}
          </span>
        </div>

        {loading && <LoadingState message="Searching TMT bus routes..." />}
        {error && <ErrorState message={error} onRetry={() => onSearch(searchParams)} />}

        {!loading && !error && results.length === 0 && (
          <EmptyState
            title="No Routes Found"
            message={`No TMT bus routes found for "${searchParams.from || 'Origin'}" → "${searchParams.to || 'Destination'}". Try: Thane Station, Airoli, Mulund, Vashi, Borivali.`}
          />
        )}

        {!loading && !error && results.length > 0 && (
          <div className="results-grid">
            {results.map((route) => (
              <RouteCard
                key={route.id}
                route={route}
                onViewRoute={() => onSelectRoute(route)}
                onTrackBus={() => onTrackBus(route)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
