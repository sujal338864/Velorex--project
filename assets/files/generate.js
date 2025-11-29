const fs = require('fs');

const categories = ['Mobiles', 'Laptops', 'Tablets', 'Accessories', 'Appliances'];
const items = [];

for (let i = 1; i <= 1000; i++) {
  const cat = categories[i % categories.length];
  items.push({
    id: i,
    name: `${cat} Product ${i}`,
    desc: `Description for ${cat} Product ${i}`,
    price: Math.floor(Math.random() * 150000) + 10000,
    color: '#' + Math.floor(Math.random() * 16777215).toString(16),
    category: cat,
    image: `https://example.com/images/${cat.toLowerCase()}_${i}.jpg`
  });
}

items.push({
  id: 1001,
  name: "M4 Macbook Air",
  desc: "Apple Macbook Air with Apple Silicon A14",
  price: 89900,
  color: "#e0bfae",
  category: "Laptops",
  image: "https://store.storeimages.cdn-apple.com/..."
});

fs.writeFileSync('products.json', JSON.stringify({ products: items }, null, 2));
console.log(`✅ Generated products.json with ${items.length} products`);
