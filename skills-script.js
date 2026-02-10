/**
 * Skills Page Interactive Script
 * Gère les cartes interactives, modales et sous-catégories
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    animationDuration: 300,
    escapeKey: 'Escape',
    hoverDelay: 200
  };

  // Éléments DOM
  const elements = {
    backdrop: document.getElementById('modalBackdrop'),
    breadcrumb: document.getElementById('breadcrumb'),
    breadcrumbCurrent: document.getElementById('breadcrumbCurrent'),
    breadcrumbHome: document.getElementById('breadcrumbHome'),
    cards: document.querySelectorAll('.comp-card'),
    subcats: document.querySelectorAll('.subcat-card'),
    grid: document.getElementById('cardsGrid')
  };

  // État de l'application
  let state = {
    expandedCard: null,
    isTransitioning: false,
    hoverTimer: null,
    scrollPosition: 0
  };

  /**
   * Ouvre une carte en mode étendu (modal)
   * @param {HTMLElement} card - La carte à étendre
   */
  function openCard(card) {
    if (state.isTransitioning || state.expandedCard) return;
    
    state.isTransitioning = true;
    state.scrollPosition = window.scrollY;
    state.expandedCard = card;
    
    // Masquer les autres cartes
    elements.cards.forEach(c => {
      if (c !== card) c.classList.add('hidden');
    });
    
    // Animer l'ouverture
    requestAnimationFrame(() => {
      card.classList.add('expanded');
      elements.backdrop.classList.add('visible');
      
      // Mettre à jour le breadcrumb
      const title = card.querySelector('.card-title');
      if (title) {
        elements.breadcrumbCurrent.textContent = title.textContent;
      }
      elements.breadcrumb.classList.add('visible');
      
      // Bloquer le scroll de la page
      document.body.style.overflow = 'hidden';
      document.body.style.position = 'fixed';
      document.body.style.top = `-${state.scrollPosition}px`;
      document.body.style.width = '100%';
    });
    
    // Débloquer l'état après l'animation
    setTimeout(() => {
      state.isTransitioning = false;
    }, config.animationDuration);
  }

  /**
   * Ferme la carte étendue et retourne à la grille
   */
  function closeCard() {
    if (state.isTransitioning || !state.expandedCard) return;
    
    state.isTransitioning = true;
    state.expandedCard.classList.remove('expanded');
    
    setTimeout(() => {
      // Réafficher toutes les cartes
      elements.cards.forEach(c => c.classList.remove('hidden'));
      state.expandedCard = null;
      
      // Fermer toutes les sous-catégories
      elements.subcats.forEach(s => s.classList.remove('active'));
      
      // Masquer le backdrop et breadcrumb
      elements.backdrop.classList.remove('visible');
      elements.breadcrumb.classList.remove('visible');
      
      // Restaurer le scroll
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
      document.body.style.overflow = '';
      window.scrollTo(0, state.scrollPosition);
      
      // Débloquer l'état
      setTimeout(() => {
        state.isTransitioning = false;
      }, config.animationDuration);
    }, 50);
  }

  /**
   * Toggle une sous-catégorie (ouvre/ferme)
   * @param {HTMLElement} subcat - La sous-catégorie à toggler
   * @param {boolean} forceOpen - Force l'ouverture sans fermer les autres
   */
  function toggleSubcategory(subcat, forceOpen = false) {
    const wasActive = subcat.classList.contains('active');
    const parent = subcat.closest('.subcategories');
    
    // Fermer les autres sous-catégories du même parent
    if (parent && !forceOpen) {
      parent.querySelectorAll('.subcat-card').forEach(s => {
        s.classList.remove('active');
      });
    }
    
    // Ouvrir si elle était fermée (ou si forceOpen)
    if (!wasActive || forceOpen) {
      subcat.classList.add('active');
      
      // Scroll vers la sous-catégorie si elle est hors de vue
      if (state.expandedCard) {
        const cardBody = state.expandedCard.querySelector('.card-body');
        const subcatRect = subcat.getBoundingClientRect();
        const cardRect = cardBody.getBoundingClientRect();
        
        if (subcatRect.bottom > cardRect.bottom - 100) {
          subcat.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
      }
    }
  }

  /**
   * Configure tous les écouteurs d'événements
   */
  function setupEventListeners() {
    // Click sur les cartes pour les étendre
    elements.cards.forEach(card => {
      card.addEventListener('click', function(e) {
        // Ignorer si on clique sur le bouton retour ou une sous-catégorie
        if (e.target.closest('.back-btn') || e.target.closest('.subcat-card')) {
          return;
        }
        if (!state.expandedCard) {
          openCard(this);
        }
      });
    });

    // Boutons de retour
    document.querySelectorAll('.back-btn').forEach(btn => {
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        closeCard();
      });
    });

    // Click sur le backdrop pour fermer
    elements.backdrop.addEventListener('click', closeCard);
    
    // Click sur le breadcrumb home pour fermer
    elements.breadcrumbHome.addEventListener('click', closeCard);

    // Hover sur les sous-catégories (uniquement si carte étendue)
    elements.subcats.forEach(subcat => {
      subcat.addEventListener('mouseenter', function() {
        if (!state.expandedCard) return;
        
        if (state.hoverTimer) clearTimeout(state.hoverTimer);
        
        state.hoverTimer = setTimeout(() => {
          toggleSubcategory(this, true);
        }, config.hoverDelay);
      });
      
      subcat.addEventListener('mouseleave', function() {
        if (state.hoverTimer) {
          clearTimeout(state.hoverTimer);
          state.hoverTimer = null;
        }
      });
      
      // Click sur les sous-catégories
      subcat.addEventListener('click', function(e) {
        e.stopPropagation();
        if (state.hoverTimer) clearTimeout(state.hoverTimer);
        toggleSubcategory(this);
      });
    });

    // Touche Échap pour fermer
    document.addEventListener('keydown', function(e) {
      if (e.key === config.escapeKey && state.expandedCard) {
        closeCard();
      }
    });

    // Prévenir le scroll quand modal ouverte
    window.addEventListener('scroll', function() {
      if (state.expandedCard && document.body.style.position === 'fixed') {
        window.scrollTo(0, state.scrollPosition);
      }
    });
  }

  /**
   * Initialisation de l'application
   */
  function init() {
    setupEventListeners();
    
    // Nettoyage avant déchargement de la page
    window.addEventListener('beforeunload', () => {
      if (state.hoverTimer) clearTimeout(state.hoverTimer);
    });
    
    console.log('✅ Skills page initialized');
  }

  // Démarrer quand le DOM est prêt
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
