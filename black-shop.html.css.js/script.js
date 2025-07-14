// Firebase and Checkout Functionality
document.addEventListener("DOMContentLoaded", () => {
  // Ensure checkoutPopup and related elements exist before adding listeners
  const checkoutBtn = document.getElementById("checkout-btn");
  const checkoutPopup = document.getElementById("checkoutPopup");
  const closeBtn = document.querySelector(".close-btn");
  const checkoutForm = document.getElementById("checkoutForm");
  // Initialize the site
  initializeShop();
  if (checkoutBtn && checkoutPopup && closeBtn && checkoutForm) {
    // Open Checkout Popup
    checkoutBtn.addEventListener("click", () => {
      // Use the existing getCart() function from your main script
      const cart = getCart();
      if (cart.length === 0) {
        showNotification(
          "Your cart is empty. Please add items before checkout.",
          "error"
        );
        return;
      }
      checkoutPopup.style.display = "block";
    });

    // Close Checkout Popup
    closeBtn.addEventListener("click", () => {
      checkoutPopup.style.display = "none";
    });

    // Handle Form Submission
    checkoutForm.addEventListener("submit", (e) => {
      e.preventDefault();

      // Get Form Values
      const name = document.getElementById("name").value;
      const email = document.getElementById("email").value;
      const address = document.getElementById("address").value;
      const phone = document.getElementById("phone").value;

      // Get Products from Cart
      const cart = getCart();

      // Validate cart is not empty
      if (cart.length === 0) {
        showNotification("Cannot place order. Cart is empty.", "error");
        return;
      }

      // Calculate Total
      const total = cart.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );

      // Create Order Object
      const orderData = {
        customerInfo: {
          name,
          email,
          address,
          phone,
        },
        products: cart,
        total: total,
        timestamp: firebase.database.ServerValue.TIMESTAMP,
      };

      // Save to Firebase
      database
        .ref("orders")
        .push(orderData)
        .then(() => {
          showNotification("Order placed successfully!");

          // Clear cart
          localStorage.removeItem("cart");

          // Close popup
          checkoutPopup.style.display = "none";

          // Reset form
          checkoutForm.reset();

          // Update cart UI
          updateCart();
        })
        .catch((error) => {
          console.error("Error saving order:", error);
          showNotification("Failed to place order. Please try again.", "error");
        });
    });

    // Close popup if clicked outside
    window.addEventListener("click", (e) => {
      if (e.target === checkoutPopup) {
        checkoutPopup.style.display = "none";
      }
    });
  }
});

// Firebase Configuration
const firebaseConfig = {

};
    firebase.initializeApp(firebaseConfig);
const database = firebase.database();
// Main initialization function
function initializeShop() {
  // Update cart display
  updateCart();

  // Initialize wishlist
  updateWishlist();

  // Dark mode functionality
  initializeDarkMode();

  // Search functionality
  initializeSearch();

  // Category filter
  initializeCategoryFilter();

  // Quick view functionality
  initializeQuickView();

  // Back to top button
  initializeBackToTop();

  // Newsletter form
  initializeNewsletter();

  // Add sale badges and ratings to products
  addProductBadgesAndRatings();
}

// Function to initialize dark mode
function initializeDarkMode() {
  const darkModeToggle = document.getElementById("dark-mode-toggle");
  if (darkModeToggle) {
    // Check if user has a saved preference
    const darkModeSaved = localStorage.getItem("dark-mode") === "true";
    if (darkModeSaved) {
      document.body.classList.add("dark-mode");
      darkModeToggle.checked = true;
    }

    darkModeToggle.addEventListener("change", () => {
      document.body.classList.toggle("dark-mode", darkModeToggle.checked);
      localStorage.setItem("dark-mode", darkModeToggle.checked);
    });
  }
}

// Function to initialize search
function initializeSearch() {
  const searchInput = document.getElementById("search-input");
  if (searchInput) {
    searchInput.addEventListener("input", () => {
      const searchTerm = searchInput.value.toLowerCase();
      const products = document.querySelectorAll(".product");

      products.forEach((product) => {
        const productName = product.getAttribute("data-name").toLowerCase();
        const description =
          product.querySelector(".description")?.textContent.toLowerCase() ||
          "";

        if (
          productName.includes(searchTerm) ||
          description.includes(searchTerm)
        ) {
          product.style.display = "block";
        } else {
          product.style.display = "none";
        }
      });
    });
  }
}

// Function to initialize category filter
function initializeCategoryFilter() {
  const categoryFilters = document.querySelectorAll(".category-filter");
  if (categoryFilters.length > 0) {
    categoryFilters.forEach((filter) => {
      filter.addEventListener("click", () => {
        const category = filter.getAttribute("data-category");
        const products = document.querySelectorAll(".product");

        // Remove active class from all filters
        categoryFilters.forEach((f) => f.classList.remove("active-filter"));

        // Add active class to clicked filter
        filter.classList.add("active-filter");

        // Filter products
        filterProducts(products, category);
      });
    });
  }
}

// Function to filter products by category
function filterProducts(products, category) {
  products.forEach((product) => {
    if (
      category === "all" ||
      product.getAttribute("data-category") === category
    ) {
      product.style.display = "block";
    } else {
      product.style.display = "none";
    }
  });
}

// Function to initialize back to top button
function initializeBackToTop() {
  const backToTopBtn = document.getElementById("back-to-top");
  if (backToTopBtn) {
    window.addEventListener("scroll", () => {
      if (window.pageYOffset > 300) {
        backToTopBtn.style.display = "flex";
      } else {
        backToTopBtn.style.display = "none";
      }
    });

    backToTopBtn.addEventListener("click", () => {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }
}

// Function to add quick view, sale badges and wishlist buttons to products
function addProductBadgesAndRatings() {
  const products = document.querySelectorAll(".product");

  products.forEach((product) => {
    const productName = product.getAttribute("data-name");

    // Add random sale badge to some products (20% chance)
    if (Math.random() < 0.2) {
      const discount = Math.floor(Math.random() * 30) + 10; // 10-40% discount
      const saleBadge = document.createElement("div");
      saleBadge.className = "sale-badge";
      saleBadge.textContent = `${discount}% OFF`;
      product.appendChild(saleBadge);
    }

    // Add quick view button
    const quickViewBtn = document.createElement("div");
    quickViewBtn.className = "quick-view";
    quickViewBtn.innerHTML = '<i class="fas fa-eye"></i>';
    quickViewBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      openQuickView(productName);
    });
    product.appendChild(quickViewBtn);

    // Add wishlist button
    const wishlistBtn = document.createElement("button");
    wishlistBtn.className = "wishlist-btn";
    wishlistBtn.innerHTML = '<i class="fas fa-heart"></i>';

    // Check if product is in wishlist
    if (isInWishlist(productName)) {
      wishlistBtn.classList.add("active");
    }

    wishlistBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      toggleWishlist(productName);
      wishlistBtn.classList.toggle("active");
    });

    product.appendChild(wishlistBtn);
  });
}

// Function to initialize quick view
function initializeQuickView() {
  // Create modal container if it doesn't exist
  if (!document.querySelector(".modal-overlay")) {
    const modalOverlay = document.createElement("div");
    modalOverlay.className = "modal-overlay";

    const quickViewModal = document.createElement("div");
    quickViewModal.className = "quick-view-modal";

    modalOverlay.appendChild(quickViewModal);
    document.body.appendChild(modalOverlay);

    // Close modal when clicking outside
    modalOverlay.addEventListener("click", (e) => {
      if (e.target === modalOverlay) {
        closeQuickView();
      }
    });
  }
}

// Function to open quick view modal
function openQuickView(productName) {
  const product = document.querySelector(
    `.product[data-name="${productName}"]`
  );
  if (!product) return;

  const modalOverlay = document.querySelector(".modal-overlay");
  const quickViewModal = document.querySelector(".quick-view-modal");

  // Get product details
  const imageUrl = product.querySelector("img").src;
  const price = product.querySelector("p").textContent;
  const description = product.querySelector(".description").textContent;

  // Build modal content
  quickViewModal.innerHTML = `
            <div class="modal-header">
                <h2>${productName}</h2>
                <button class="modal-close">&times;</button>
            </div>
            <div class="modal-body">
                <div class="modal-image">
                    <img src="${imageUrl}" alt="${productName}">
                </div>
                <div class="modal-info">
                    <div class="modal-price">${price}</div>
                    <div class="modal-description">${description}</div>
                    <div class="size-options">
                        <h3>Select Size</h3>
                        <div class="size-selector">
                            <button class="size-btn">S</button>
                            <button class="size-btn">M</button>
                            <button class="size-btn">L</button>
                            <button class="size-btn">XL</button>
                            <button class="size-btn">XXL</button>
                            <button class="size-btn">final size</button>
                        </div>
                    </div>
                    <div class="color-options">
                        <h3>Select Color</h3>
                        <div class="color-selector">
                            <div class="color-btn" style="background-color: #000000;"></div>
                            <div class="color-btn" style="background-color: #0066cc;"></div>
                            <div class="color-btn" style="background-color: #cc0000;"></div>
                            <div class="color-btn" style="background-color: #009933;"></div>
                        </div>
                    </div>
                    <div class="reviews-section">
                        <h3>Customer Reviews</h3>
                        <div class="stars">
                            ${generateRandomStars()}
                        </div>
                        <div class="review">
                            <div class="review-header">
                                <span class="reviewer-name">John Doe</span>
                                <span class="review-date">3 days ago</span>
                            </div>
                            <div class="stars">${generateRandomStars()}</div>
                            <div class="review-text">
                                Great product! Very comfortable and stylish. Highly recommend it to anyone looking for quality clothing.
                            </div>
                        </div>
                    </div>
                    <div class="modal-actions">
                        <div class="quantity-control">
                            <button class="quantity-btn minus">-</button>
                            <div class="quantity-display">1</div>
                            <button class="quantity-btn plus">+</button>
                        </div>
                        <button class="add-to-cart-btn" data-product="${productName}">Add to Cart</button>
                        <button class="add-to-wishlist-btn ${
                          isInWishlist(productName) ? "active" : ""
                        }" data-product="${productName}">
                            <i class="fas fa-heart"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;

  // Setup event listeners
  const closeBtn = quickViewModal.querySelector(".modal-close");
  closeBtn.addEventListener("click", closeQuickView);

  // Size buttons
  const sizeBtns = quickViewModal.querySelectorAll(".size-btn");
  sizeBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      sizeBtns.forEach((b) => b.classList.remove("selected"));
      btn.classList.add("selected");
    });
  });

  // Color buttons
  const colorBtns = quickViewModal.querySelectorAll(".color-btn");
  colorBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      colorBtns.forEach((b) => b.classList.remove("selected"));
      btn.classList.add("selected");
    });
  });

  // Quantity controls
  const minusBtn = quickViewModal.querySelector(".quantity-btn.minus");
  const plusBtn = quickViewModal.querySelector(".quantity-btn.plus");
  const quantityDisplay = quickViewModal.querySelector(".quantity-display");
  let quantity = 1;

  minusBtn.addEventListener("click", () => {
    if (quantity > 1) {
      quantity--;
      quantityDisplay.textContent = quantity;
    }
  });

  plusBtn.addEventListener("click", () => {
    quantity++;
    quantityDisplay.textContent = quantity;
  });

  // Add to cart button
  const addToCartBtn = quickViewModal.querySelector(".add-to-cart-btn");
  addToCartBtn.addEventListener("click", () => {
    addToCartWithQuantity(productName, quantity);
    closeQuickView();
  });

  // Add to wishlist button
  const wishlistBtn = quickViewModal.querySelector(".add-to-wishlist-btn");
  wishlistBtn.addEventListener("click", () => {
    toggleWishlist(productName);
    wishlistBtn.classList.toggle("active");
  });

  // Show modal
  modalOverlay.classList.add("active");
}

// Function to close quick view modal
function closeQuickView() {
  const modalOverlay = document.querySelector(".modal-overlay");
  modalOverlay.classList.remove("active");
}

// Function to generate random stars for reviews
function generateRandomStars() {
  const rating = Math.floor(Math.random() * 2) + 4; // 4-5 stars (biased toward positive)
  return "★".repeat(rating) + "☆".repeat(5 - rating);
}

// Function to get wishlist from localStorage
function getWishlist() {
  return JSON.parse(localStorage.getItem("wishlist")) || [];
}

// Function to update wishlist
function updateWishlist() {
  const wishlist = getWishlist();
  const wishlistCount = document.getElementById("wishlist-count");

  if (wishlistCount) {
    wishlistCount.textContent = wishlist.length;
    wishlistCount.style.display = wishlist.length > 0 ? "flex" : "none";
  }

  // Update wishlist page if on that page
  const wishlistItems = document.getElementById("wishlist-items");
  if (wishlistItems) {
    if (wishlist.length === 0) {
      wishlistItems.innerHTML =
        "<p class='empty-wishlist'>Your wishlist is empty</p>";
    } else {
      wishlistItems.innerHTML = "";

      wishlist.forEach((productName) => {
        // Find product data from the shop
        const product = document.querySelector(
          `.product[data-name="${productName}"]`
        );
        if (product) {
          const imageUrl = product.querySelector("img").src;
          const price = product.querySelector("p").textContent;

          const wishlistItem = document.createElement("div");
          wishlistItem.className = "product";
          wishlistItem.innerHTML = `
                            <img src="${imageUrl}" alt="${productName}">
                            <h2>${productName}</h2>
                            <p>${price}</p>
                            <button onclick="addToCart('${productName}')">Add to Cart</button>
                            <button class="remove-from-wishlist" data-product="${productName}">Remove</button>
                        `;

          wishlistItems.appendChild(wishlistItem);
        }
      });

      // Add event listeners to remove buttons
      document.querySelectorAll(".remove-from-wishlist").forEach((btn) => {
        btn.addEventListener("click", () => {
          const productName = btn.getAttribute("data-product");
          toggleWishlist(productName);
          updateWishlist();
        });
      });
    }
  }
}

// Function to check if product is in wishlist
function isInWishlist(productName) {
  const wishlist = getWishlist();
  return wishlist.includes(productName);
}

// Function to toggle product in wishlist
function toggleWishlist(productName) {
  let wishlist = getWishlist();

  if (isInWishlist(productName)) {
    wishlist = wishlist.filter((item) => item !== productName);
  } else {
    wishlist.push(productName);
  }

  localStorage.setItem("wishlist", JSON.stringify(wishlist));
  updateWishlist();

  // Update all wishlist buttons for this product
  document
    .querySelectorAll(`.wishlist-btn[data-product="${productName}"]`)
    .forEach((btn) => {
      btn.classList.toggle("active", isInWishlist(productName));
    });

  // Show notification
  showNotification(
    isInWishlist(productName)
      ? `${productName} added to wishlist!`
      : `${productName} removed from wishlist!`
  );
}

// Function to get cart from localStorage
function getCart() {
  return JSON.parse(localStorage.getItem("cart")) || [];
}

// Function to update the cart UI
function updateCart() {
  let cart = getCart();
  const cartItems = document.getElementById("cart-items");
  const totalPrice = document.getElementById("total-price");
  const cartCount = document.getElementById("cart-count");

  // Update cart count in the header
  if (cartCount) {
    const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
    console.log(totalItems);

    cartCount.textContent = totalItems;
    cartCount.style.display = totalItems > 0 ? "flex" : "none";
  }

  if (cartItems) {
    if (cart.length === 0) {
      cartItems.innerHTML = "<p class='empty-cart'>Your cart is empty</p>";
    } else {
      cartItems.innerHTML = "";

      // Create cart items
      cart.forEach((item) => {
        const cartItem = document.createElement("div");
        cartItem.className = "cart-item";
        cartItem.innerHTML = `
                        <div class="cart-item-details">
                            <h3>${item.name}</h3>
                            <p>$${item.price.toFixed(2)} each</p>
                        </div>
                        <div class="cart-item-quantity">
                            <button class="quantity-btn minus" data-product="${
                              item.name
                            }">-</button>
                            <span>${item.quantity}</span>
                            <button class="quantity-btn plus" data-product="${
                              item.name
                            }">+</button>
                        </div>
                        <div class="cart-item-total">
                            <p>$${(item.price * item.quantity).toFixed(2)}</p>
                        </div>
                        <button class="remove-btn" data-product="${
                          item.name
                        }">×</button>
                    `;
        cartItems.appendChild(cartItem);
      });

      // Add event listeners for quantity buttons and remove buttons
      document.querySelectorAll(".quantity-btn.minus").forEach((btn) => {
        btn.addEventListener("click", () =>
          updateQuantity(btn.getAttribute("data-product"), -1)
        );
      });

      document.querySelectorAll(".quantity-btn.plus").forEach((btn) => {
        btn.addEventListener("click", () =>
          updateQuantity(btn.getAttribute("data-product"), 1)
        );
      });

      document.querySelectorAll(".remove-btn").forEach((btn) => {
        btn.addEventListener("click", () =>
          removeFromCart(btn.getAttribute("data-product"))
        );
      });
    }

    // Calculate the total price of the cart
    let total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
    if (totalPrice) {
      totalPrice.innerText = total.toFixed(2);
    }
  }
}

// Function to add item to the cart
function addToCart(productName) {
  addToCartWithQuantity(productName, 1);
}

// Function to add item to cart with specified quantity
function addToCartWithQuantity(productName, quantity) {
  if (quantity <= 0) return;

  let cart = getCart();

  // Find the product element to get the price
  const productElement = document.querySelector(
    `.product[data-name="${productName}"]`
  );
  if (!productElement) return;

  // Extract price from the product element
  const priceText = productElement.querySelector("p").textContent;
  const price = parseFloat(priceText.replace(/[^0-9.-]+/g, ""));

  // Check if item is already in the cart
  const existingItem = cart.find((item) => item.name === productName);

  if (existingItem) {
    existingItem.quantity += quantity;
  } else {
    // If new item, add to cart with specified quantity
    cart.push({ name: productName, price: price, quantity: quantity });
  }

  // Save the updated cart to localStorage
  localStorage.setItem("cart", JSON.stringify(cart));

  // Show notification instead of alert
  showNotification(
    `${quantity} ${productName}${quantity > 1 ? "s" : ""} added to cart!`
  );

  // Update the cart display
  updateCart();
}

// Function to update quantity of an item in cart
function updateQuantity(productName, change) {
  let cart = getCart();
  const item = cart.find((item) => item.name === productName);

  if (item) {
    item.quantity += change;

    if (item.quantity <= 0) {
      // Remove item if quantity is 0 or less
      cart = cart.filter((item) => item.name !== productName);
    }

    localStorage.setItem("cart", JSON.stringify(cart));
    updateCart();
  }
}

// Function to remove an item from cart
function removeFromCart(productName) {
  let cart = getCart();
  cart = cart.filter((item) => item.name !== productName);
  localStorage.setItem("cart", JSON.stringify(cart));
  updateCart();

  showNotification(`${productName} removed from cart!`);
}

// Function to initialize newsletter form
function initializeNewsletter() {
  const newsletterForm = document.querySelector(".newsletter-form");
  if (newsletterForm) {
    newsletterForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const emailInput = newsletterForm.querySelector("input[type='email']");
      const email = emailInput.value.trim();

      if (email) {
        // In a real app, you would send this to a server
        emailInput.value = "";
        showNotification("Thanks for subscribing to our newsletter!");
      }
    });
  }
}

// Function to show notification
function showNotification(message, type = "success") {
  const notification = document.createElement("div");
  notification.className = `notification ${type}`;
  notification.innerHTML = `
            <div class="notification-content">
                <i class="fas ${
                  type === "success"
                    ? "fa-check-circle"
                    : "fa-exclamation-circle"
                }"></i>
                <span>${message}</span>
            </div>
            <button class="notification-close"><i class="fas fa-times"></i></button>
        `;

  document.body.appendChild(notification);

  // Show with animation
  setTimeout(() => {
    notification.classList.add("show");
  }, 10);

  // Auto close after 3 seconds
  setTimeout(() => {
    notification.classList.remove("show");
    setTimeout(() => {
      notification.remove();
    }, 300);
  }, 3000);

  // Close button functionality
  notification
    .querySelector(".notification-close")
    .addEventListener("click", () => {
      notification.classList.remove("show");
      setTimeout(() => {
        notification.remove();
      }, 300);
    });
}
