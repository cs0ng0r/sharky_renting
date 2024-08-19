let vehicleRentalUI = document.getElementById("vehicle-rental-ui");
let header = document.getElementById("ui-header");
let closeButton = document.getElementById("close-btn");

let isDragging = false;
let offsetX, offsetY;

header.onmousedown = function (event) {
  isDragging = true;

  offsetX = event.clientX - vehicleRentalUI.offsetLeft;
  offsetY = event.clientY - vehicleRentalUI.offsetTop;
};

document.onmousemove = function (event) {
  if (isDragging) {
    vehicleRentalUI.style.left = event.clientX - offsetX + "px";
    vehicleRentalUI.style.top = event.clientY - offsetY + "px";
  }
};

document.onmouseup = function () {
  isDragging = false;
};

closeButton.onclick = function () {
  fetch(`https://${GetParentResourceName()}/closeMenu`, {
    method: "POST",
    body: JSON.stringify({}),
  })
    .then((resp) => resp.json())
    .then((resp) => {});
};

window.addEventListener("message", function (event) {
  let data = event.data;

  if (data.action === "openMenu") {
    populateMenu(data.vehicles);
    vehicleRentalUI.style.display = "block";
    setTimeout(() => {
      vehicleRentalUI.classList.add("show");
    }, 10);
  } else if (data.action === "closeMenu") {
    vehicleRentalUI.classList.remove("show");
    setTimeout(() => {
      vehicleRentalUI.style.display = "none";
    }, 300);
  }
});

function populateMenu(vehicles) {
  let content = document.getElementById("ui-content");
  content.innerHTML = "";

  vehicles.forEach((vehicle) => {
    let vehicleOption = document.createElement("div");
    vehicleOption.className = "vehicle-option";

    vehicleOption.innerHTML = `
            <div>
                <span class="vehicle-name">${vehicle.name}</span>
                <span class="vehicle-price" style="color: #42b289">$${vehicle.price} + $${vehicle.caution} (kaució)</span>
            </div>
            <button class="rent-btn" onclick="rentVehicle('${vehicle.model}', ${vehicle.price}, ${vehicle.caution})">Bérlés</button>
        `;

    content.appendChild(vehicleOption);
  });
}

function rentVehicle(model, price, caution) {
  fetch(`https://${GetParentResourceName()}/rentVehicle`, {
    method: "POST",
    body: JSON.stringify({ model: model, price: price, caution: caution }),
  })
    .then((resp) => resp.json())
    .then((resp) => {});
}

document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    fetch(`https://${GetParentResourceName()}/closeMenu`, { method: "POST" });
  }
});
