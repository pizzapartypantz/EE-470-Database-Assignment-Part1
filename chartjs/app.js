
$(document).ready(function () {

    // Read the selected node from graph.html's URL
    const params = new URLSearchParams(window.location.search);
    const node = params.get("node") || "node_1";

    $.ajax({
        url: "data.php",
        method: "GET",
        data: { node: node },
        dataType: "json",

        success: function (data) {

            const x_axis = [];
            const y_axis = [];

            for (let i = 0; i < data.length; i++) {
                x_axis.push(data[i].time_received);
                y_axis.push(Number(data[i].temperature));
            }

            const chartdata = {
                labels: x_axis,
                datasets: [{
                    label: "Temperature",
                    backgroundColor: "rgba(0, 255, 0, 0.8)",
                    borderColor: "rgba(0, 255, 0, 1)",
                    hoverBackgroundColor: "rgba(200, 200, 200, 1)",
                    hoverBorderColor: "rgba(200, 200, 200, 1)",
                    data: y_axis
                }]
            };

            const ctx = document.getElementById("mycanvas");

            new Chart(ctx, {
                type: "line",
                data: chartdata,

                options: {
                    responsive: true,
                    maintainAspectRatio: true,

                    plugins: {
                        title: {
                            display: true,
                            text: "Sensor " + node,
                            color: "white",
                            font: { size: 18 }
                        },

                        legend: {
                            labels: { color: "white" }
                        }
                    },

                    scales: {
                        x: {
                            title: {
                                display: true,
                                text: "Time",
                                color: "white"
                            },
                            ticks: { color: "white" }
                        },

                        y: {
                            title: {
                                display: true,
                                text: "Temperature",
                                color: "white"
                            },
                            ticks: { color: "white" }
                        }
                    }
                }
            });
        },

        error: function (xhr) {
            console.error(
                "Failed to load sensor data:",
                xhr.responseText
            );
        }
    });
});
