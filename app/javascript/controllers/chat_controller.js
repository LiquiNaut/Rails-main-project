import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ['messages', 'input', 'sendButton', 'imageUpload', 'imageLabel'];

  static values = { chatAskPath: String, chatId: Number };

  connect() {
    console.log('Chat controller connected!');
    this.imageData = null;
    this.isSending = false;
    this.scrollToBottom();
    this.inputTarget.focus();
  }

  disconnect() {
    console.log('Chat controller disconnected!');
  }

  sendMessage() {
    if (this.isSending) {
      console.warn('sendMessage aborted: Already sending.');
      return;
    }

    const prompt = this.inputTarget.value.trim();

    if (!prompt && !this.imageData) {
      console.log('sendMessage aborted: No prompt or image data.');
      this.inputTarget.placeholder = 'Prosím, zadajte správu alebo nahrajte obrázok.';
      setTimeout(() => {
        this.inputTarget.placeholder = 'Napíšte správu...';
      }, 2000);
      return;
    }

    this.isSending = true;
    this.disableForm();

    this.addMessage('user', prompt || '(Odoslaný obrázok)');
    const requestData = {
      prompt: prompt,
      image: this.imageData,
      chat_id: this.chatIdValue || null,
    };

    this.inputTarget.value = '';
    const hadImage = !!this.imageData;
    this.imageData = null;
    if (hadImage && this.hasImageUploadTarget) {
      this.imageUploadTarget.value = '';
      if (this.hasImageLabelTarget) {
        this.imageLabelTarget.textContent = 'Nahrať obrázok';
      }
    }

    console.log(`Sending fetch request to: ${this.chatAskPathValue}`);
    fetch(this.chatAskPathValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken,
        Accept: 'application/json',
      },
      body: JSON.stringify(requestData),
    })
      .then((response) => {
        console.log(`Fetch response status: ${response.status}`);
        if (!response.ok) {
          return response.text().then((text) => {
            throw new Error(`Server error: ${response.status} - ${text}`);
          });
        }
        return response.json();
      })
      .then((data) => {
        console.log('Fetch response data (JSON):', data);
        if (!data) {
          this.addMessage('system', 'Chyba: Server vrátil neplatnú odpoveď.');
          return;
        }

        if (data.chart_data) {
          if (Array.isArray(data.chart_data)) {
            data.chart_data.forEach((chartData) => this.renderChart(chartData));
          } else {
            this.renderChart(data.chart_data);
          }
        }

        if (data.response && data.response.trim()) {
          this.addMessage('ai', data.response);
        }
      })
      .catch((error) => {
        console.error('Fetch Error:', error);
        this.addMessage('system', `Nastala chyba pri komunikácii: ${error.message}`);
      })
      .finally(() => {
        console.log('Fetch finished.');
        this.isSending = false;
        this.enableForm();
      });
  }

  sendMessageOnEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.sendMessage();
    }
  }

  handleImageUpload(event) {
    const file = event.target.files[0];
    const targetInput = event.target;

    if (file) {
      this.addMessage('system', `Nahrávam obrázok: ${file.name}...`);
      const reader = new FileReader();

      reader.onloadend = () => {
        this.imageData = reader.result;
        console.log('Image loaded into this.imageData.');
        this.addMessage(
          'system',
          `Obrázok ${file.name} je pripravený na odoslanie s ďalšou správou.`
        );
        if (this.hasImageLabelTarget) {
          this.imageLabelTarget.textContent = file.name;
        }
      };

      reader.onerror = () => {
        console.error('Error reading file.');
        this.addMessage('system', `Chyba pri nahrávaní obrázka ${file.name}.`);
        this.imageData = null;
        targetInput.value = '';
        if (this.hasImageLabelTarget) {
          this.imageLabelTarget.textContent = 'Nahrať obrázok';
        }
      };
      reader.readAsDataURL(file);
    } else {
      this.imageData = null;
      if (this.hasImageLabelTarget) {
        this.imageLabelTarget.textContent = 'Nahrať obrázok';
      }
    }
  }

  addMessage(sender, text) {
    if (!this.hasMessagesTarget || !text || text.trim() === '') return;
    console.log(`Adding message - Sender: ${sender}`);

    const messageDiv = document.createElement('div');
    messageDiv.className = `${sender}-message mb-3`;

    const messagePara = document.createElement('p');
    messagePara.className = sender === 'user' ? 'text-end' : 'text-start';

    const span = document.createElement('span');
    let spanClasses = 'p-2 rounded d-inline-block';
    if (sender === 'user') {
      spanClasses += ' bg-light';
    } else if (sender === 'ai') {
      spanClasses += ' bg-primary text-white';
    } else {
      messagePara.className = 'system-message';
      spanClasses = '';
    }
    if (spanClasses) span.setAttribute('class', spanClasses);

    span.textContent = text;
    messagePara.appendChild(span);
    messageDiv.appendChild(messagePara);

    this.messagesTarget.appendChild(messageDiv);
    this.scrollToBottom();
  }

  renderChart(chartData) {
    if (!this.hasMessagesTarget || !chartData?.chart_type) return;

    const messageDiv = document.createElement('div');
    messageDiv.className = 'ai-message mb-3';

    const canvasWrapper = document.createElement('div');
    canvasWrapper.style.cssText = [
      'max-width: 560px',
      'background: white',
      'padding: 16px',
      'border-radius: 8px',
      'box-shadow: 0 1px 4px rgba(0,0,0,0.12)',
      'display: inline-block',
    ].join(';');

    const canvas = document.createElement('canvas');
    canvas.id = `chart-${Date.now()}`;
    canvas.style.maxHeight = '300px';

    canvasWrapper.appendChild(canvas);
    messageDiv.appendChild(canvasWrapper);
    this.messagesTarget.appendChild(messageDiv);
    this.scrollToBottom();

    import('chart.js')
      .then(({ Chart, registerables }) => {
        Chart.register(...registerables);

        if (chartData.chart_type === 'cashflow_bar') {
          new Chart(canvas, {
            type: 'bar',
            data: {
              labels: chartData.labels,
              datasets: chartData.datasets.map((d) => ({
                label: d.label,
                data: d.data,
                backgroundColor: d.color + 'bb',
                borderColor: d.color,
                borderWidth: 1,
              })),
            },
            options: {
              responsive: true,
              plugins: {
                legend: { position: 'top' },
                title: {
                  display: true,
                  text: chartData.title || 'Cashflow',
                },
              },
              scales: {
                y: {
                  beginAtZero: true,
                  ticks: {
                    callback: (v) => v.toLocaleString('sk-SK') + ' €',
                  },
                },
              },
            },
          });
        } else if (chartData.chart_type === 'income_pie') {
          new Chart(canvas, {
            type: 'doughnut',
            data: {
              labels: chartData.labels,
              datasets: [
                {
                  data: chartData.data,
                  backgroundColor: chartData.colors,
                  borderWidth: 2,
                },
              ],
            },
            options: {
              responsive: true,
              plugins: {
                legend: { position: 'right' },
                title: {
                  display: true,
                  text: chartData.title || 'Príjmy podľa klienta',
                },
                tooltip: {
                  callbacks: {
                    label: (ctx) => ` ${ctx.label}: ${ctx.parsed.toLocaleString('sk-SK')} €`,
                  },
                },
              },
            },
          });
        }
      })
      .catch((err) => {
        console.error('Chart.js načítanie zlyhalo:', err);
        canvasWrapper.innerHTML =
          "<p class='text-danger small p-2'>Graf sa nepodarilo načítať.</p>";
      });
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

  get csrfToken() {
    const tokenElement = document.querySelector('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.content : null;
  }
}
