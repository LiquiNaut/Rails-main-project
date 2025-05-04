import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = [ "messages", "input", "sendButton", "imageUpload", "imageLabel" ]
  // Definuje HTML elementy, ku ktorým budeme pristupovať cez this.messagesTarget, this.inputTarget atď.

  static values = { chatAskPath: String } // Cesta pre fetch request

  connect() {
    console.log("Chat controller connected!");
    this.imageData = null;
    this.isSending = false;
    this.scrollToBottom(); // Preskrolujeme na koniec pri načítaní
    this.inputTarget.focus(); // Focus na input pri načítaní
  }

  disconnect() {
    // Tu môžete pridať logiku na čistenie, ak je potrebná pri odstránení kontroléra z DOM
    console.log("Chat controller disconnected!");
  }

  // --- Akcie kontroléra ---

  // Spustí sa pri kliknutí na tlačidlo s data-action="click->chat#sendMessage"
  // alebo pri stlačení Enter v inpute s data-action="keypress->chat#sendMessageOnEnter"
  sendMessage() {
    if (this.isSending) {
      console.warn("sendMessage aborted: Already sending.");
      return;
    }

    const prompt = this.inputTarget.value.trim();

    if (!prompt && !this.imageData) {
      console.log("sendMessage aborted: No prompt or image data.");
      // Môžete pridať vizuálnu spätnú väzbu, napr. zmenou placeholderu
      this.inputTarget.placeholder = "Prosím, zadajte správu alebo nahrajte obrázok.";
      setTimeout(() => { this.inputTarget.placeholder = "Napíšte správu..."; }, 2000);
      return;
    }

    this.isSending = true;
    this.disableForm();

    this.addMessage('user', prompt || '(Odoslaný obrázok)');
    const requestData = {
      prompt: prompt,
      image: this.imageData // Posielame Base64 dáta obrázka
    };

    // Reset inputu a obrázka
    this.inputTarget.value = '';
    const hadImage = !!this.imageData;
    this.imageData = null;
    if (hadImage && this.hasImageUploadTarget) {
        this.imageUploadTarget.value = ''; // Reset file inputu
        if (this.hasImageLabelTarget) {
          // Môžete aktualizovať aj label, ak ho používate na zobrazenie názvu súboru
          this.imageLabelTarget.textContent = "Nahrať obrázok";
        }
    }

    console.log(`Sending fetch request to: ${this.chatAskPathValue}`);
    fetch(this.chatAskPathValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken, // CSRF token získaný nižšie
        'Accept': 'application/json'
      },
      body: JSON.stringify(requestData)
    })
    .then(response => {
      console.log(`Fetch response status: ${response.status}`);
      if (!response.ok) {
        return response.text().then(text => {
          throw new Error(`Server error: ${response.status} - ${text}`);
        });
      }
      return response.json();
    })
    .then(data => {
      console.log('Fetch response data (JSON):', data);
      if (data && data.response) {
        this.addMessage('ai', data.response);
      } else {
        console.error('Invalid response format:', data);
        this.addMessage('system', 'Chyba: Server vrátil neplatnú odpoveď.');
      }
    })
    .catch(error => {
      console.error('Fetch Error:', error);
      this.addMessage('system', `Nastala chyba pri komunikácii: ${error.message}`);
    })
    .finally(() => {
      console.log('Fetch finished.');
      this.isSending = false;
      this.enableForm();
    });
  }

  // Spustí sa pri stlačení klávesy v inpute
  sendMessageOnEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault(); // Zabráni vloženiu nového riadku
      this.sendMessage();
    }
  }

  // Spustí sa pri zmene v inpute typu file (data-action="change->chat#handleImageUpload")
  handleImageUpload(event) {
    const file = event.target.files[0];
    const targetInput = event.target; // Uložíme si referenciu na file input

    if (file) {
      this.addMessage('system', `Nahrávam obrázok: ${file.name}...`);
      const reader = new FileReader();

      reader.onloadend = () => {
        this.imageData = reader.result; // Uložíme base64 dáta
        console.log('Image loaded into this.imageData.');
        this.addMessage('system', `Obrázok ${file.name} je pripravený na odoslanie s ďalšou správou.`);
        if(this.hasImageLabelTarget) {
           // Aktualizujeme label, ak existuje
           this.imageLabelTarget.textContent = file.name;
        }
      }

      reader.onerror = () => {
        console.error("Error reading file.");
        this.addMessage('system', `Chyba pri nahrávaní obrázka ${file.name}.`);
        this.imageData = null;
        targetInput.value = ''; // Reset file inputu aj pri chybe
         if(this.hasImageLabelTarget) {
           this.imageLabelTarget.textContent = "Nahrať obrázok";
        }
      }
      reader.readAsDataURL(file);

    } else {
      this.imageData = null;
      if(this.hasImageLabelTarget) {
           this.imageLabelTarget.textContent = "Nahrať obrázok";
      }
    }
  }

  // --- Pomocné metódy ---

  addMessage(sender, text) {
    if (!this.hasMessagesTarget || !text || text.trim() === '') return; // Kontrola, či máme kam pridať a či text nie je prázdny
    console.log(`Adding message - Sender: ${sender}`);

    const messageDiv = document.createElement('div');
    messageDiv.className = `${sender}-message mb-3`;

    const messagePara = document.createElement('p');
    messagePara.className = sender === 'user' ? 'text-end' : 'text-start';

    const span = document.createElement('span');
    // Bezpečnejšie pridanie tried - priamo nastavíme atribút class
    let spanClasses = 'p-2 rounded d-inline-block';
    if (sender === 'user') {
        spanClasses += ' bg-light';
    } else if (sender === 'ai') {
        spanClasses += ' bg-primary text-white';
    } else { // Pre 'system' správy môžeme použiť iný štýl alebo žiadny
        messagePara.className = 'system-message'; // Použijeme špecifickú triedu pre systémové správy
        spanClasses = ''; // Systémové správy nemusia mať pozadie
    }
    if(spanClasses) span.setAttribute('class', spanClasses);

    // Bezpečné vloženie textu
    span.textContent = text;
    messagePara.appendChild(span);
    messageDiv.appendChild(messagePara);

    this.messagesTarget.appendChild(messageDiv);
    this.scrollToBottom();
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
    }
  }

  disableForm() {
    if (this.hasInputTarget) this.inputTarget.disabled = true;
    if (this.hasSendButtonTarget) this.sendButtonTarget.disabled = true;
    if (this.hasImageUploadTarget) this.imageUploadTarget.disabled = true;
  }

  enableForm() {
    if (this.hasInputTarget) {
        this.inputTarget.disabled = false;
        this.inputTarget.focus();
    }
    if (this.hasSendButtonTarget) this.sendButtonTarget.disabled = false;
    if (this.hasImageUploadTarget) this.imageUploadTarget.disabled = false;
  }

  // Getter pre jednoduchší prístup k CSRF tokenu
  get csrfToken() {
    const tokenElement = document.querySelector('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.content : null;
  }
}