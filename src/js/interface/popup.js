let popup = null;

function getPopup() {
  if( popup ){
    return popup;
  }

  popup = document.createElement('div');

  popup.id = 'popup-overlay';
  popup.style.display = 'none';

  popup.addEventListener('click', () => Popup.hide() );

  document.body.appendChild(popup);

  return popup;
}

const Popup = {
  show: (content) => {
    let popup = getPopup();

    popup.innerHTML = content;

    popup.style.display = 'block';
  },
  hide: () => {
    getPopup().style.display = 'none';
  }
}

export{ Popup }
